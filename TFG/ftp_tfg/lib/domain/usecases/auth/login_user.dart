import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';

class LoginUser {
  final AuthRepository repository;

  LoginUser(this.repository);

  Future<AppUser> execute({
    required String email,
    required String password,
  }) =>
      repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
}
