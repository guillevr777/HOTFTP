import '../entities/ftp_profile.dart';

abstract class IDeleteProfileUseCase {
  Future<void> execute(FtpProfile profile, String ownerId);
}
