import '../entities/dump_schedule.dart';
import '../repositories/ftp_repository.dart';
import '../interfaces/i_get_dump_schedule_for_profile_use_case.dart';

class GetDumpScheduleForProfile implements IGetDumpScheduleForProfileUseCase {
  final FtpRepository repository;

  GetDumpScheduleForProfile(this.repository);

  @override
  Future<DumpSchedule?> execute(String ownerId, int profileId) =>
      repository.getDumpScheduleForProfile(ownerId, profileId);
}




