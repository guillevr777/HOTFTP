import '../entities/dump_schedule.dart';
abstract class ISaveDumpScheduleUseCase {
  Future<int> execute(DumpSchedule schedule);
}





