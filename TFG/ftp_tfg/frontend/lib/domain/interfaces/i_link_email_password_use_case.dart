import '../entities/app_user.dart';
abstract class ILinkEmailPasswordUseCase {
  Future<AppUser> execute(String password);
}





