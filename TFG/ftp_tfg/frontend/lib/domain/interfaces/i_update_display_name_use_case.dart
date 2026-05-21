import '../entities/app_user.dart';
abstract class IUpdateDisplayNameUseCase {
  Future<AppUser> execute(String displayName);
}





