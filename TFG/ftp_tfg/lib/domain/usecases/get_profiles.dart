import '../repositories/ftp_repository.dart';
import '../entities/ftp_profile.dart';

class GetProfiles {
  final FtpRepository repository;
  GetProfiles(this.repository);
  Future<List<FtpProfile>> execute() => repository.getProfiles();
}
