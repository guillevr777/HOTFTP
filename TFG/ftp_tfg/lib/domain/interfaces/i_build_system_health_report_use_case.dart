import '../entities/file_version.dart';
import '../entities/system_alert.dart';
import '../entities/system_event.dart';
import '../entities/system_health_summary.dart';
import '../entities/system_recommendation.dart';
import '../entities/system_usage_stats.dart';
import '../entities/sync_record.dart';
abstract class IBuildSystemHealthReportUseCase {
  String execute({
    required SystemHealthSummary summary,
    required List<SystemEvent> recentEvents,
    required List<SystemAlert> activeAlerts,
    required List<SyncRecord> recentSyncs,
    required List<FileVersion> recentFileVersions,
    required List<SystemRecommendation> recommendations,
    required SystemUsageStats? usageStats,
    required DateTime generatedAt,
  });
}





