import '../repositories/ftp_repository.dart';
import '../entities/ftp_profile.dart';

class TestConnection {
  final FtpRepository repository;
  TestConnection(this.repository);
  Future<bool> execute(FtpProfile profile) => repository.testConnection(profile);
}
