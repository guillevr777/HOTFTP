import 'package:flutter/material.dart';

import '../../domain/entities/system_alert.dart';
import '../../domain/entities/file_version.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/system_event.dart';
import '../../domain/entities/system_health_summary.dart';
import '../../domain/entities/system_recommendation.dart';
import '../../domain/entities/system_usage_stats.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/entities/dump_schedule.dart';
import '../../core/services/health_report_export_service.dart';
import '../../domain/interfaces/i_acknowledge_alert_use_case.dart';
import '../../domain/interfaces/i_analyze_system_usage_use_case.dart';
import '../../domain/interfaces/i_build_system_health_report_use_case.dart';
import '../../domain/interfaces/i_generate_system_recommendations_use_case.dart';
import '../../domain/interfaces/i_get_active_alerts_use_case.dart';
import '../../domain/interfaces/i_get_health_summary_use_case.dart';
import '../../domain/interfaces/i_get_profiles_use_case.dart';
import '../../domain/interfaces/i_get_dump_schedule_for_profile_use_case.dart';
import '../../domain/interfaces/i_get_recent_events_use_case.dart';
import '../../domain/interfaces/i_get_recent_file_versions_use_case.dart';
import '../../domain/interfaces/i_get_recent_syncs_use_case.dart';

class SystemHealthViewModel extends ChangeNotifier {
  final IGetHealthSummaryUseCase _getHealthSummary;
  final IGetRecentEventsUseCase _getRecentEvents;
  final IGetActiveAlertsUseCase _getActiveAlerts;
  final IGetRecentSyncsUseCase _getRecentSyncs;
  final IGetRecentFileVersionsUseCase _getRecentFileVersions;
  final IGetProfilesUseCase _getProfiles;
  final IGetDumpScheduleForProfileUseCase _getDumpScheduleForProfile;
  final IAcknowledgeAlertUseCase _acknowledgeAlert;
  final String ownerId;
  final IBuildSystemHealthReportUseCase _buildSystemHealthReport;
  final HealthReportExportService _exportService;
  final IGenerateSystemRecommendationsUseCase _generateRecommendations;
  final IAnalyzeSystemUsageUseCase _analyzeSystemUsage;

  SystemHealthViewModel({
    required IGetHealthSummaryUseCase getHealthSummary,
    required IGetRecentEventsUseCase getRecentEvents,
    required IGetActiveAlertsUseCase getActiveAlerts,
    required IGetRecentSyncsUseCase getRecentSyncs,
    required IGetRecentFileVersionsUseCase getRecentFileVersions,
    required IGetProfilesUseCase getProfiles,
    required IGetDumpScheduleForProfileUseCase getDumpScheduleForProfile,
    required IAcknowledgeAlertUseCase acknowledgeAlert,
    required this.ownerId,
    required IBuildSystemHealthReportUseCase buildSystemHealthReport,
    required HealthReportExportService exportService,
    required IGenerateSystemRecommendationsUseCase generateSystemRecommendations,
    required IAnalyzeSystemUsageUseCase analyzeSystemUsage,
  })  : _getHealthSummary = getHealthSummary,
        _getRecentEvents = getRecentEvents,
        _getActiveAlerts = getActiveAlerts,
        _getRecentSyncs = getRecentSyncs,
        _getRecentFileVersions = getRecentFileVersions,
        _getProfiles = getProfiles,
        _getDumpScheduleForProfile = getDumpScheduleForProfile,
        _acknowledgeAlert = acknowledgeAlert,
        _buildSystemHealthReport = buildSystemHealthReport,
        _exportService = exportService,
        _generateRecommendations = generateSystemRecommendations,
        _analyzeSystemUsage = analyzeSystemUsage;

  SystemHealthSummary? summary;
  List<SystemEvent> recentEvents = [];
  List<SystemAlert> activeAlerts = [];
  List<SyncRecord> recentSyncs = [];
  List<FileVersion> recentFileVersions = [];
  List<SystemRecommendation> recommendations = [];
  SystemUsageStats? usageStats;
  bool isLoading = false;
  String? error;
  String? lastExportPath;
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _getHealthSummary.execute(ownerId),
        _getRecentEvents.execute(ownerId, limit: 15),
        _getActiveAlerts.execute(ownerId, limit: 10),
        _getRecentSyncs.execute(ownerId, limit: 20),
        _getRecentFileVersions.execute(ownerId, limit: 12),
        _getProfiles.execute(ownerId),
      ]);
      summary = results[0] as SystemHealthSummary;
      recentEvents = results[1] as List<SystemEvent>;
      activeAlerts = results[2] as List<SystemAlert>;
      recentSyncs = results[3] as List<SyncRecord>;
      recentFileVersions = results[4] as List<FileVersion>;
      final profiles = results[5] as List<FtpProfile>;
      final schedules = await Future.wait(
        profiles.map((profile) async {
          if (profile.id == null) return null;
          try {
            return await _getDumpScheduleForProfile.execute(ownerId, profile);
          } catch (_) {
            return null;
          }
        }),
      );
      final scheduleAlerts = <SystemAlert>[
        for (var i = 0; i < profiles.length; i++)
          if (schedules[i] != null && schedules[i]!.enabled)
            _buildScheduleAlert(
              profile: profiles[i],
              schedule: schedules[i]!,
            ),
      ];
      activeAlerts = [...activeAlerts, ...scheduleAlerts]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      usageStats = _analyzeSystemUsage.execute(
        syncs: recentSyncs,
        profiles: profiles,
      );
      recommendations = _generateRecommendations.execute(
        summary: summary!,
        activeAlerts: activeAlerts,
        recentSyncs: recentSyncs,
      );
    } catch (e) {
      error = 'No se pudo cargar el estado del sistema: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acknowledgeAlert(SystemAlert alert) async {
    if (alert.id == null) return;
    await _acknowledgeAlert.execute(alert.id!, ownerId);
    await load();
  }

  Future<bool> exportHealthReport() async {
    if (summary == null) {
      error = 'No hay datos suficientes para generar un informe.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final content = _buildSystemHealthReport.execute(
        summary: summary!,
        recentEvents: recentEvents,
        activeAlerts: activeAlerts,
        recentSyncs: recentSyncs,
        recentFileVersions: recentFileVersions,
        recommendations: recommendations,
        usageStats: usageStats,
        generatedAt: DateTime.now(),
      );
      lastExportPath = await _exportService.export(content);
      return true;
    } catch (e) {
      error = 'No se pudo generar el informe: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  SystemAlert _buildScheduleAlert({
    required FtpProfile profile,
    required DumpSchedule schedule,
  }) {
    final cadenceUnit = schedule.intervalValue == 1
        ? switch (schedule.intervalUnit) {
            DumpIntervalUnit.minutes => 'minuto',
            DumpIntervalUnit.hours => 'hora',
            DumpIntervalUnit.days => 'día',
          }
        : switch (schedule.intervalUnit) {
            DumpIntervalUnit.minutes => 'minutos',
            DumpIntervalUnit.hours => 'horas',
            DumpIntervalUnit.days => 'días',
          };
    final transferModeLabel = schedule.transferMode == DumpTransferMode.syncBoth
        ? 'bidireccional'
        : schedule.sourceSide == DumpSourceSide.local
            ? 'de local a remoto'
            : 'de remoto a local';
    final transportLabel = profile.transportType == FtpTransportType.api
        ? 'API'
        : 'directa';
    final nextRun = schedule.nextRunAt ?? schedule.calculateNextRun(DateTime.now());
    return SystemAlert(
      ownerId: ownerId,
      source: 'schedule',
      severity: SystemAlertSeverity.warning,
      title: 'Sincronización programada: ${profile.name}',
      message:
          'Conexión $transportLabel, modo $transferModeLabel, cada ${schedule.intervalValue} $cadenceUnit. Próxima ejecución: ${formatDateTime(nextRun.toLocal())}.',
      relatedProfileId: profile.id,
      createdAt: DateTime.now(),
    );
  }
}




