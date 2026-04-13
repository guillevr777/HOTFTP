import '../entities/ftp_profile.dart';
import '../repositories/ftp_repository.dart';

class SaveProfile {
  final FtpRepository repository;

  SaveProfile(this.repository);

  Future<int> execute(FtpProfile profile, String ownerId) =>
      repository.saveProfile(profile, ownerId);
}
