import '../repositories/monitoring_repository.dart';
import '../interfaces/i_acknowledge_alert_use_case.dart';

class AcknowledgeAlert implements IAcknowledgeAlertUseCase {
  final MonitoringRepository repository;

  AcknowledgeAlert(this.repository);

  @override
  Future<void> execute(int alertId, String ownerId) =>
      repository.acknowledgeAlert(alertId, ownerId);
}




