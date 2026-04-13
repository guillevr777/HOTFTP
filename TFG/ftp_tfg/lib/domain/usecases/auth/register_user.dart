import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';

class RegisterUser {
  final AuthRepository repository;

  RegisterUser(this.repository);

  Future<AppUser> execute({
    required String email,
    required String password,
    required String displayName,
  }) =>
      repository.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
}
