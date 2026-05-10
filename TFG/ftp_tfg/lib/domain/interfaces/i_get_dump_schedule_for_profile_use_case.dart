import '../entities/dump_schedule.dart';
abstract class IGetDumpScheduleForProfileUseCase {
  Future<DumpSchedule?> execute(String ownerId, int profileId);
}





