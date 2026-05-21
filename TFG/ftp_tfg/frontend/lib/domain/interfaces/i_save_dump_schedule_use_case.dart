import '../entities/dump_schedule.dart';
import '../entities/ftp_profile.dart';

abstract class ISaveDumpScheduleUseCase {
  Future<int> execute(DumpSchedule schedule, FtpProfile profile);
}
