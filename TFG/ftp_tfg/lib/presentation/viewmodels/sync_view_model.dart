import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/services/dump_transfer_service.dart';
import '../../domain/entities/dump_schedule.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/system_alert.dart';
import '../../domain/entities/system_event.dart';
import '../../domain/entities/sync_conflict.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/interfaces/i_create_alert_use_case.dart';
import '../../domain/interfaces/i_detect_conflicts_use_case.dart';
import '../../domain/interfaces/i_evaluate_sync_rules_use_case.dart';
import '../../domain/interfaces/i_get_active_alerts_use_case.dart';
import '../../domain/interfaces/i_get_sync_history_use_case.dart';
import '../../domain/interfaces/i_record_event_use_case.dart';
import '../../domain/interfaces/i_save_sync_record_use_case.dart';

enum SyncMode { push, pull, bidirectional }

class SyncViewModel extends ChangeNotifier {
  final IDetectConflictsUseCase _detectConflicts;
  final ISaveSyncRecordUseCase _saveSyncRecord;
  final IGetSyncHistoryUseCase _getSyncHistory;
  final IGetActiveAlertsUseCase _getActiveAlerts;
  final IEvaluateSyncRulesUseCase _evaluateSyncRules;
  final IRecordEventUseCase _recordEvent;
  final ICreateAlertUseCase _createAlert;
  final FtpProfile profile;
  final String ownerId;
  final DumpTransferService transferService;

  SyncViewModel({
    required IDetectConflictsUseCase detectConflicts,
    required ISaveSyncRecordUseCase saveSyncRecord,
    required IGetSyncHistoryUseCase getSyncHistory,
    required IGetActiveAlertsUseCase getActiveAlerts,
    required IEvaluateSyncRulesUseCase evaluateSyncRules,
    required IRecordEventUseCase recordEvent,
    required ICreateAlertUseCase createAlert,
    required this.profile,
    required this.ownerId,
    required this.transferService,
  })  : _detectConflicts = detectConflicts,
        _saveSyncRecord = saveSyncRecord,
        _getSyncHistory = getSyncHistory,
        _getActiveAlerts = getActiveAlerts,
        _evaluateSyncRules = evaluateSyncRules,
        _recordEvent = recordEvent,
        _createAlert = createAlert;

  SyncMode syncMode = SyncMode.bidirectional;
  String localPath = '/storage/emulated/0/Download';
  String remotePath = '/';
  bool isSyncing = false;
  bool isDone = false;
  int filesTransferred = 0;
  int filesSkipped = 0;
  int directoriesCreated = 0;
  int processedItems = 0;
  int totalItems = 0;
  String syncStatus = 'Preparando sincronización...';
  String? currentItemPath;
  String? error;
  List<SyncConflict> conflicts = [];
  List<SyncRecord> history = [];

  void setSyncMode(SyncMode mode) {
    syncMode = mode;
    notifyListeners();
  }

  void setLocalPath(String value) {
    localPath = value.trim();
    notifyListeners();
  }

  void setRemotePath(String value) {
    remotePath = _normalizeRemotePath(value);
    notifyListeners();
  }

  String _normalizeRemotePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '/';
    if (trimmed == '/') return '/';
    final normalized = p.posix.normalize(trimmed);
    return normalized.startsWith('/') ? normalized : '/$normalized';
  }

  Future<void> startSync() async {
    isSyncing = true;
    isDone = false;
    filesTransferred = 0;
    filesSkipped = 0;
    directoriesCreated = 0;
    processedItems = 0;
    totalItems = 0;
    currentItemPath = null;
    syncStatus = 'Preparando sincronización...';
    error = null;
    conflicts = [];
    notifyListeners();
    try {
      await _trackEvent(
        eventType: 'sync_started',
        severity: SystemEventSeverity.info,
        title: 'SincronizaciÃ³n iniciada',
        message: 'Se ha iniciado la sincronizaciÃ³n manual.',
      );
      conflicts = await _detectConflicts.execute(localPath, remotePath, profile);
      final transferMode = syncMode == SyncMode.bidirectional
          ? DumpTransferMode.syncBoth
          : DumpTransferMode.oneWay;
      final sourceSide = syncMode == SyncMode.pull
          ? DumpSourceSide.remote
          : DumpSourceSide.local;
      final result = await transferService.execute(
        profile: profile,
        localPath: localPath.isEmpty
            ? '/storage/emulated/0/Download'
            : localPath,
        remotePath: remotePath.isEmpty ? '/' : remotePath,
        transferMode: transferMode,
        sourceSide: sourceSide,
        deleteSourceAfterCopy: false,
        onProgress: (progress) {
          processedItems = progress.processed;
          totalItems = progress.total;
          filesTransferred = progress.transferred;
          filesSkipped = progress.skipped;
          directoriesCreated = progress.directoriesCreated;
          currentItemPath = progress.currentPath;
          syncStatus = _statusFor(progress);
          notifyListeners();
        },
      );
      filesTransferred = result.transferred;
      filesSkipped = result.skipped;
      directoriesCreated = result.directoriesCreated;
      processedItems = totalItems == 0 ? processedItems : totalItems;
      currentItemPath = null;
      syncStatus = 'Sincronización completada';
      await _saveSyncRecord.execute(
        SyncRecord(
          ownerId: ownerId,
          profileId: profile.id ?? 0,
          date: DateTime.now(),
          localPath: localPath,
          remotePath: remotePath,
          mode: syncMode.name,
          filesTransferred: filesTransferred,
          filesSkipped: filesSkipped,
        ),
        profile,
      );
      await _applyAutomaticRules();
      await _trackEvent(
        eventType: 'sync_completed',
        severity: SystemEventSeverity.success,
        title: 'SincronizaciÃ³n completada',
        message:
            'Se han transferido $filesTransferred archivos, se han creado $directoriesCreated carpetas y se han omitido $filesSkipped elementos.',
      );
      isDone = true;
    } catch (e) {
      error = 'Error durante la sincronizacion: $e';
      await _trackEvent(
        eventType: 'sync_failed',
        severity: SystemEventSeverity.error,
        title: 'Error de sincronizaciÃ³n',
        message: error!,
      );
      await _trackAlert(
        source: 'sync',
        severity: SystemAlertSeverity.error,
        title: 'SincronizaciÃ³n con error',
        message: error!,
      );
      await _applyAutomaticRules();
    }
    isSyncing = false;
    notifyListeners();
  }

  double get syncProgress {
    if (totalItems <= 0) return 0;
    return (processedItems / totalItems).clamp(0.0, 1.0);
  }

  String get syncSummaryText {
    return 'Transferidos: $filesTransferred  |  Carpetas: $directoriesCreated  |  Omitidos: $filesSkipped';
  }

  String _statusFor(DumpTransferProgress progress) {
    final path = progress.currentPath ?? '';
    final label = _shortenPath(path);
    switch (progress.stage) {
      case 'creating_remote_directory':
      case 'creating_local_directory':
        return 'Creando carpeta $label';
      case 'uploading':
        return 'Subiendo $label';
      case 'downloading':
        return 'Descargando $label';
      case 'skipping':
        return 'Omitiendo $label';
      case 'syncing_directory':
        return 'Revisando carpeta $label';
      default:
        return 'Preparando sincronización...';
    }
  }

  String _shortenPath(String path) {
    if (path.length <= 72) return path;
    return '...${path.substring(path.length - 69)}';
  }

  Future<void> loadHistory() async {
    history = await _getSyncHistory.execute(ownerId);
    notifyListeners();
  }

  Future<void> _trackEvent({
    required String eventType,
    required SystemEventSeverity severity,
    required String title,
    required String message,
  }) async {
    try {
      await _recordEvent.execute(
        SystemEvent(
          ownerId: ownerId,
          eventType: eventType,
          severity: severity,
          title: title,
          message: message,
          relatedProfileId: profile.id,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // La monitorizaciÃ³n nunca debe bloquear la sincronizaciÃ³n.
    }
  }

  Future<void> _trackAlert({
    required String source,
    required SystemAlertSeverity severity,
    required String title,
    required String message,
  }) async {
    try {
      await _createAlert.execute(
        SystemAlert(
          ownerId: ownerId,
          source: source,
          severity: severity,
          title: title,
          message: message,
          relatedProfileId: profile.id,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // No interrumpimos la UX si el sistema de alertas falla.
    }
  }

  Future<void> _applyAutomaticRules() async {
    try {
      final recentSyncs = await _getSyncHistory.execute(ownerId);
      final activeAlerts = await _getActiveAlerts.execute(ownerId, limit: 20);
      final alerts = _evaluateSyncRules.execute(
        ownerId: ownerId,
        profileId: profile.id ?? 0,
        profileName: profile.name,
        recentSyncs: recentSyncs,
        activeAlerts: activeAlerts,
      );
      for (final alert in alerts) {
        await _createAlert.execute(alert);
      }
    } catch (_) {
      // Las reglas automÃ¡ticas no deben romper la sincronizaciÃ³n manual.
    }
  }
}




