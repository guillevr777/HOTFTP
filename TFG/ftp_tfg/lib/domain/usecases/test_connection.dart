import '../entities/ftp_profile.dart';
import '../repositories/ftp_repository.dart';
import '../interfaces/i_test_connection_use_case.dart';

class TestConnection implements ITestConnectionUseCase {
  final FtpRepository repository;
  TestConnection(this.repository);
  @override
  Future<bool> execute(FtpProfile profile) => repository.testConnection(profile);
}




