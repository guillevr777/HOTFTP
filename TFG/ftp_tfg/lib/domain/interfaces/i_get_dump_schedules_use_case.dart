import '../entities/dump_schedule.dart';
abstract class IGetDumpSchedulesUseCase {
  Future<List<DumpSchedule>> execute(String ownerId);
}





