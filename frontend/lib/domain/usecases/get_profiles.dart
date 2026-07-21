import '../entities/ftp_profile.dart';
import '../repositories/ftp_repository.dart';
import '../interfaces/i_get_profiles_use_case.dart';

class GetProfiles implements IGetProfilesUseCase {
  final FtpRepository repository;

  GetProfiles(this.repository);

  @override
  Future<List<FtpProfile>> execute(String ownerId) =>
      repository.getProfiles(ownerId);
}




