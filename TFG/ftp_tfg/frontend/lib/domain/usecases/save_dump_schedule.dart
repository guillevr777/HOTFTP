import '../entities/dump_schedule.dart';
import '../entities/ftp_profile.dart';
import '../interfaces/i_save_dump_schedule_use_case.dart';
import '../repositories/ftp_repository.dart';

class SaveDumpSchedule implements ISaveDumpScheduleUseCase {
  final FtpRepository repository;

  SaveDumpSchedule(this.repository);

  @override
  Future<int> execute(DumpSchedule schedule, FtpProfile profile) =>
      repository.saveDumpSchedule(schedule, profile);
}
