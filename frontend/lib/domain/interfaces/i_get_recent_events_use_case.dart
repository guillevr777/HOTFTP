import '../entities/system_event.dart';
abstract class IGetRecentEventsUseCase {
  Future<List<SystemEvent>> execute(String ownerId, {int limit});
}





