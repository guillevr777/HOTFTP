import '../entities/ftp_profile.dart';
abstract class IGetProfilesUseCase {
  Future<List<FtpProfile>> execute(String ownerId);
}





