import '../entities/system_health_summary.dart';
abstract class IGetHealthSummaryUseCase {
  Future<SystemHealthSummary> execute(String ownerId);
}





