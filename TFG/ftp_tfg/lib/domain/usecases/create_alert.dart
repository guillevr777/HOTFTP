import '../entities/system_alert.dart';
import '../repositories/monitoring_repository.dart';
import '../interfaces/i_create_alert_use_case.dart';

class CreateAlert implements ICreateAlertUseCase {
  final MonitoringRepository repository;

  CreateAlert(this.repository);

  @override
  Future<int> execute(SystemAlert alert) => repository.createAlert(alert);
}




