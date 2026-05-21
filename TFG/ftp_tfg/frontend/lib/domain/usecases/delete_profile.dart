import '../entities/ftp_profile.dart';
import '../interfaces/i_delete_profile_use_case.dart';
import '../repositories/ftp_repository.dart';

class DeleteProfile implements IDeleteProfileUseCase {
  final FtpRepository repository;

  DeleteProfile(this.repository);

  @override
  Future<void> execute(FtpProfile profile, String ownerId) =>
      repository.deleteProfile(profile, ownerId);
}
