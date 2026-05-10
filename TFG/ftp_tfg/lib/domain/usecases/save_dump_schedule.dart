import '../entities/dump_schedule.dart';
import '../repositories/ftp_repository.dart';
import '../interfaces/i_save_dump_schedule_use_case.dart';

class SaveDumpSchedule implements ISaveDumpScheduleUseCase {
  final FtpRepository repository;

  SaveDumpSchedule(this.repository);

  @override
  Future<int> execute(DumpSchedule schedule) =>
      repository.saveDumpSchedule(schedule);
}




