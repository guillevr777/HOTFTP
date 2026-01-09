import '../entities/ftp_profile.dart';
import '../interfaces/i_connect_ftp.dart';
import '../repositories/ftp_repository.dart';

class ConnectFtp implements IConnectFtp {
  final FtpRepository repository;

  ConnectFtp(this.repository);

  @override
  Future<bool> execute(FtpProfile profile) {
    return repository.connect(profile);
  }
}
