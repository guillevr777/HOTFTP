import '../entities/system_alert.dart';
import '../entities/sync_record.dart';
abstract class IEvaluateSyncRulesUseCase {
  List<SystemAlert> execute({
    required String ownerId,
    required int profileId,
    required String profileName,
    required List<SyncRecord> recentSyncs,
    required List<SystemAlert> activeAlerts,
    DateTime? now,
  });
}





