import '../entities/app_user.dart';
abstract class ILoginUserUseCase {
  Future<AppUser> execute({
    required String email,
    required String password,
  });
}





