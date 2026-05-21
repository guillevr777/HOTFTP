import '../entities/ftp_profile.dart';
abstract class ISaveProfileUseCase {
  Future<int> execute(FtpProfile profile, String ownerId);
}





