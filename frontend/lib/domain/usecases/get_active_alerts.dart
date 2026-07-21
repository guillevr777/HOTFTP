import '../entities/system_alert.dart';
import '../repositories/monitoring_repository.dart';
import '../interfaces/i_get_active_alerts_use_case.dart';

class GetActiveAlerts implements IGetActiveAlertsUseCase {
  final MonitoringRepository repository;

  GetActiveAlerts(this.repository);

  @override
  Future<List<SystemAlert>> execute(String ownerId, {int limit = 10}) =>
      repository.getActiveAlerts(ownerId, limit: limit);
}




