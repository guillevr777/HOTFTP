import '../entities/app_user.dart';
abstract class IRegisterUserUseCase {
  Future<AppUser> execute({
    required String email,
    required String password,
    required String displayName,
  });
}





