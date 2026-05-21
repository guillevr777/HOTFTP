import '../entities/system_event.dart';
abstract class IRecordEventUseCase {
  Future<void> execute(SystemEvent event);
}





