import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/services/dump_transfer_service.dart';
import '../../domain/entities/dump_schedule.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/system_alert.dart';
import '../../domain/entities/system_event.dart';
import '../../domain/entities/sync_conflict.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../../domain/repositories/monitoring_repository.dart';
import '../../domain/usecases/evaluate_sync_rules.dart';

enum SyncMode { push, pull, bidirectional }

class SyncViewModel extends ChangeNotifier {
  final FtpRepository repository;
  final MonitoringRepository monitoringRepository;
  final FtpProfile profile;
  final String ownerId;
  SyncViewModel({
    required this.repository,
    required this.monitoringRepository,
    required this.profile,
    required this.ownerId,
  });

  SyncMode syncMode = SyncMode.bidirectional;
  String localPath = '/storage/emulated/0/Download';
  String remotePath = '/';
  bool isSyncing = false;
  bool isDone = false;
  int filesTransferred = 0;
  int filesSkipped = 0;
  String? error;
  List<SyncConflict> conflicts = [];
  List<SyncRecord> history = [];
  final EvaluateSyncRules _evaluateSyncRules = const EvaluateSyncRules();

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
    error = null;
    conflicts = [];
    notifyListeners();
    try {
      await _trackEvent(
        eventType: 'sync_started',
        severity: SystemEventSeverity.info,
        title: 'Sincronización iniciada',
        message: 'Se ha iniciado la sincronización manual.',
      );
      conflicts = await repository.detectConflicts(
        localPath,
        remotePath,
        profile,
      );
      final transferMode = syncMode == SyncMode.bidirectional
          ? DumpTransferMode.syncBoth
          : DumpTransferMode.oneWay;
      final sourceSide = syncMode == SyncMode.pull
          ? DumpSourceSide.remote
          : DumpSourceSide.local;
      final result = await DumpTransferService(repository).execute(
        profile: profile,
        localPath: localPath.isEmpty
            ? '/storage/emulated/0/Download'
            : localPath,
        remotePath: remotePath.isEmpty ? '/' : remotePath,
        transferMode: transferMode,
        sourceSide: sourceSide,
        deleteSourceAfterCopy: false,
      );
      filesTransferred = result.transferred;
      filesSkipped = result.skipped;
      await repository.saveSyncRecord(
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
      );
      await _applyAutomaticRules();
      await _trackEvent(
        eventType: 'sync_completed',
        severity: SystemEventSeverity.success,
        title: 'Sincronización completada',
        message:
            'Se han transferido $filesTransferred archivos y se han omitido $filesSkipped.',
      );
      isDone = true;
    } catch (e) {
      error = 'Error durante la sincronizacion: $e';
      await _trackEvent(
        eventType: 'sync_failed',
        severity: SystemEventSeverity.error,
        title: 'Error de sincronización',
        message: error!,
      );
      await _trackAlert(
        source: 'sync',
        severity: SystemAlertSeverity.error,
        title: 'Sincronización con error',
        message: error!,
      );
      await _applyAutomaticRules();
    }
    isSyncing = false;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    history = await repository.getSyncHistory(ownerId);
    notifyListeners();
  }

  Future<void> _trackEvent({
    required String eventType,
    required SystemEventSeverity severity,
    required String title,
    required String message,
  }) async {
    try {
      await monitoringRepository.recordEvent(
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
      // La monitorización nunca debe bloquear la sincronización.
    }
  }

  Future<void> _trackAlert({
    required String source,
    required SystemAlertSeverity severity,
    required String title,
    required String message,
  }) async {
    try {
      await monitoringRepository.createAlert(
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
      final recentSyncs = await repository.getSyncHistory(ownerId);
      final activeAlerts = await monitoringRepository.getActiveAlerts(
        ownerId,
        limit: 20,
      );
      final alerts = _evaluateSyncRules.execute(
        ownerId: ownerId,
        profileId: profile.id ?? 0,
        profileName: profile.name,
        recentSyncs: recentSyncs,
        activeAlerts: activeAlerts,
      );
      for (final alert in alerts) {
        await monitoringRepository.createAlert(alert);
      }
    } catch (_) {
      // Las reglas automáticas no deben romper la sincronización manual.
    }
  }
}
