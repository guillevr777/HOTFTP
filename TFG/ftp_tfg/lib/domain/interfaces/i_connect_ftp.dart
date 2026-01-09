import '../entities/ftp_profile.dart';

abstract class IConnectFtp {
  Future<bool> execute(FtpProfile profile);
}
