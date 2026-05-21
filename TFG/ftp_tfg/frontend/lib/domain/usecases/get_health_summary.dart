import '../entities/system_health_summary.dart';
import '../repositories/monitoring_repository.dart';
import '../interfaces/i_get_health_summary_use_case.dart';

class GetHealthSummary implements IGetHealthSummaryUseCase {
  final MonitoringRepository repository;

  GetHealthSummary(this.repository);

  @override
  Future<SystemHealthSummary> execute(String ownerId) =>
      repository.getHealthSummary(ownerId);
}




