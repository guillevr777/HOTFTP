import '../repositories/ftp_repository.dart';
import '../entities/ftp_profile.dart';

class SaveProfile {
  final FtpRepository repository;
  SaveProfile(this.repository);
  Future<int> execute(FtpProfile profile) => repository.saveProfile(profile);
}
