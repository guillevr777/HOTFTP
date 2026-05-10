import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../interfaces/i_login_user_use_case.dart';

class LoginUser implements ILoginUserUseCase {
  final AuthRepository repository;

  LoginUser(this.repository);

  @override
  Future<AppUser> execute({
    required String email,
    required String password,
  }) =>
      repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
}




