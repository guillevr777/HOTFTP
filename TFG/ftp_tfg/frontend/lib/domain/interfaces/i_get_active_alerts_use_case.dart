import '../entities/system_alert.dart';
abstract class IGetActiveAlertsUseCase {
  Future<List<SystemAlert>> execute(String ownerId, {int limit});
}





