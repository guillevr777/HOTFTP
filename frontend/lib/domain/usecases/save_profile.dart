import '../entities/ftp_profile.dart';
import '../repositories/ftp_repository.dart';
import '../interfaces/i_save_profile_use_case.dart';

class SaveProfile implements ISaveProfileUseCase {
  final FtpRepository repository;

  SaveProfile(this.repository);

  @override
  Future<int> execute(FtpProfile profile, String ownerId) =>
      repository.saveProfile(profile, ownerId);
}




