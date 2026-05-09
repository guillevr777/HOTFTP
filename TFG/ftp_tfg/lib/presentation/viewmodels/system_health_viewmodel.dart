import 'package:flutter/material.dart';

import '../../domain/entities/system_alert.dart';
import '../../domain/entities/file_version.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/system_event.dart';
import '../../domain/entities/system_health_summary.dart';
import '../../domain/entities/system_recommendation.dart';
import '../../domain/entities/system_usage_stats.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../../domain/repositories/monitoring_repository.dart';
import '../../domain/usecases/build_system_health_report.dart';
import '../../domain/usecases/generate_system_recommendations.dart';
import '../../domain/usecases/analyze_system_usage.dart';
import '../../core/services/health_report_export_service.dart';

class SystemHealthViewModel extends ChangeNotifier {
  final MonitoringRepository repository;
  final FtpRepository ftpRepository;
  final String ownerId;
  final BuildSystemHealthReport _buildSystemHealthReport =
      const BuildSystemHealthReport();
  final HealthReportExportService _exportService =
      const HealthReportExportService();

  SystemHealthViewModel({
    required this.repository,
    required this.ftpRepository,
    required this.ownerId,
  });

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
  final GenerateSystemRecommendations _generateRecommendations =
      const GenerateSystemRecommendations();
  final AnalyzeSystemUsage _analyzeSystemUsage = const AnalyzeSystemUsage();

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        repository.getHealthSummary(ownerId),
        repository.getRecentEvents(ownerId, limit: 15),
        repository.getActiveAlerts(ownerId, limit: 10),
        repository.getRecentSyncs(ownerId, limit: 20),
        repository.getRecentFileVersions(ownerId, limit: 12),
        ftpRepository.getProfiles(ownerId),
      ]);
      summary = results[0] as SystemHealthSummary;
      recentEvents = results[1] as List<SystemEvent>;
      activeAlerts = results[2] as List<SystemAlert>;
      recentSyncs = results[3] as List<SyncRecord>;
      recentFileVersions = results[4] as List<FileVersion>;
      final profiles = results[5] as List<FtpProfile>;
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
    await repository.acknowledgeAlert(alert.id!, ownerId);
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
}
