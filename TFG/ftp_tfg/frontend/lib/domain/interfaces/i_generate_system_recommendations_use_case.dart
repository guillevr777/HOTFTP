import '../entities/system_alert.dart';
import '../entities/system_health_summary.dart';
import '../entities/system_recommendation.dart';
import '../entities/sync_record.dart';
abstract class IGenerateSystemRecommendationsUseCase {
  List<SystemRecommendation> execute({
    required SystemHealthSummary summary,
    required List<SystemAlert> activeAlerts,
    required List<SyncRecord> recentSyncs,
  });
}





