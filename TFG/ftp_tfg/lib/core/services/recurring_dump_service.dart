import 'dart:async';

import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/system_alert.dart';
import '../../domain/entities/system_event.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../../domain/repositories/monitoring_repository.dart';
import 'dump_transfer_service.dart';
import '../../domain/interfaces/i_evaluate_sync_rules_use_case.dart';

class RecurringDumpService {
  final FtpRepository repository;
  final MonitoringRepository? monitoringRepository;
  final DumpTransferService transferService;
  final IEvaluateSyncRulesUseCase _evaluateSyncRules;

  Timer? _timer;
  String? _ownerId;
  bool _isProcessing = false;

  RecurringDumpService(
    this.repository, {
    this.monitoringRepository,
    required IEvaluateSyncRulesUseCase evaluateSyncRules,
  }) : transferService = DumpTransferService(repository),
       _evaluateSyncRules = evaluateSyncRules;

  void start(String ownerId) {
    if (_ownerId == ownerId && _timer != null) return;
    stop();
    _ownerId = ownerId;
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _processDueSchedules();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _ownerId = null;
  }

  Future<void> _processDueSchedules() async {
    if (_isProcessing || _ownerId == null) return;
    _isProcessing = true;
    try {
      final ownerId = _ownerId!;
      final now = DateTime.now();
      final schedules = await repository.getDumpSchedules(ownerId);
      final profiles = await repository.getProfiles(ownerId);
      for (final schedule in schedules) {
        if (!schedule.enabled) continue;
        if (schedule.nextRunAt != null && schedule.nextRunAt!.isAfter(now)) {
          continue;
        }

        final profile = _findProfile(profiles, schedule.profileId);
        if (profile == null) {
          continue;
        }

        String? errorMessage;
        int transferred = 0;
        int skipped = 0;
        await _trackEvent(
          ownerId: ownerId,
          profileId: schedule.profileId,
          eventType: 'scheduled_sync_started',
          severity: SystemEventSeverity.info,
          title: 'Volcado programado iniciado',
          message: 'Se ha lanzado el volcado recurrente.',
        );
        try {
          final result = await transferService.execute(
            profile: profile,
            localPath: schedule.localPath,
            remotePath: schedule.remotePath,
            transferMode: schedule.transferMode,
            sourceSide: schedule.sourceSide,
            deleteSourceAfterCopy: schedule.deleteSourceAfterCopy,
          );
          transferred = result.transferred;
          skipped = result.skipped;
        } catch (e) {
          errorMessage = e.toString();
        }

        if (errorMessage == null) {
          await _trackEvent(
            ownerId: ownerId,
            profileId: schedule.profileId,
            eventType: 'scheduled_sync_completed',
            severity: SystemEventSeverity.success,
            title: 'Volcado programado completado',
            message:
                'Se han transferido $transferred archivos y se han omitido $skipped.',
          );
        } else {
          await _trackEvent(
            ownerId: ownerId,
            profileId: schedule.profileId,
            eventType: 'scheduled_sync_failed',
            severity: SystemEventSeverity.error,
            title: 'Volcado programado con error',
            message: errorMessage,
          );
          await _trackAlert(
            ownerId: ownerId,
            profileId: schedule.profileId,
            source: 'schedule',
            severity: SystemAlertSeverity.error,
            title: 'Error en volcado programado',
            message: errorMessage,
          );
        }

        await repository.saveSyncRecord(
          SyncRecord(
            ownerId: ownerId,
            profileId: schedule.profileId,
            date: now,
            localPath: schedule.localPath,
            remotePath: schedule.remotePath,
            mode: 'recurrent-${schedule.transferMode.name}',
            filesTransferred: transferred,
            filesSkipped: skipped,
            errorMessage: errorMessage,
          ),
        );
        await _applyAutomaticRules(ownerId: ownerId, profile: profile);

        await repository.saveDumpSchedule(
          schedule.copyWith(
            lastRunAt: now,
            nextRunAt: schedule.calculateNextRun(now),
          ),
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _applyAutomaticRules({
    required String ownerId,
    required FtpProfile profile,
  }) async {
    final monitoring = monitoringRepository;
    if (monitoring == null) return;
    try {
      final recentSyncs = await repository.getSyncHistory(ownerId);
      final activeAlerts = await monitoring.getActiveAlerts(ownerId, limit: 20);
      final alerts = _evaluateSyncRules.execute(
        ownerId: ownerId,
        profileId: profile.id ?? 0,
        profileName: profile.name,
        recentSyncs: recentSyncs,
        activeAlerts: activeAlerts,
      );
      for (final alert in alerts) {
        await monitoring.createAlert(alert);
      }
    } catch (_) {
      // Las reglas automÃ¡ticas nunca deben bloquear la ejecuciÃ³n programada.
    }
  }

  FtpProfile? _findProfile(List<FtpProfile> profiles, int profileId) {
    for (final profile in profiles) {
      if (profile.id == profileId) return profile;
    }
    return null;
  }

  Future<void> _trackEvent({
    required String ownerId,
    required int profileId,
    required String eventType,
    required SystemEventSeverity severity,
    required String title,
    required String message,
  }) async {
    final monitoring = monitoringRepository;
    if (monitoring == null) return;
    try {
      await monitoring.recordEvent(
        SystemEvent(
          ownerId: ownerId,
          eventType: eventType,
          severity: severity,
          title: title,
          message: message,
          relatedProfileId: profileId,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {}
  }

  Future<void> _trackAlert({
    required String ownerId,
    required int profileId,
    required String source,
    required SystemAlertSeverity severity,
    required String title,
    required String message,
  }) async {
    final monitoring = monitoringRepository;
    if (monitoring == null) return;
    try {
      await monitoring.createAlert(
        SystemAlert(
          ownerId: ownerId,
          source: source,
          severity: severity,
          title: title,
          message: message,
          relatedProfileId: profileId,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {}
  }
}




