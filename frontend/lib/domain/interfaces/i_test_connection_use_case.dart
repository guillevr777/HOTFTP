import '../entities/ftp_profile.dart';
abstract class ITestConnectionUseCase {
  Future<bool> execute(FtpProfile profile);
}





