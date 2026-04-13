import '../entities/ftp_profile.dart';
import '../repositories/ftp_repository.dart';

class GetProfiles {
  final FtpRepository repository;

  GetProfiles(this.repository);

  Future<List<FtpProfile>> execute(String ownerId) =>
      repository.getProfiles(ownerId);
}
