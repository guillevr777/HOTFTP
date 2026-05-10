import '../entities/system_alert.dart';
abstract class ICreateAlertUseCase {
  Future<int> execute(SystemAlert alert);
}





