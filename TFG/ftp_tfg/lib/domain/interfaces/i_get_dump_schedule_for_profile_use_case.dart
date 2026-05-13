import '../entities/dump_schedule.dart';
import '../entities/ftp_profile.dart';

abstract class IGetDumpScheduleForProfileUseCase {
  Future<DumpSchedule?> execute(String ownerId, FtpProfile profile);
}
