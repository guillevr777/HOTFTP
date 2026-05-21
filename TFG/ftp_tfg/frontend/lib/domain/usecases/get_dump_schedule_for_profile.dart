import '../entities/dump_schedule.dart';
import '../entities/ftp_profile.dart';
import '../interfaces/i_get_dump_schedule_for_profile_use_case.dart';
import '../repositories/ftp_repository.dart';

class GetDumpScheduleForProfile implements IGetDumpScheduleForProfileUseCase {
  final FtpRepository repository;

  GetDumpScheduleForProfile(this.repository);

  @override
  Future<DumpSchedule?> execute(String ownerId, FtpProfile profile) =>
      repository.getDumpScheduleForProfile(ownerId, profile);
}
