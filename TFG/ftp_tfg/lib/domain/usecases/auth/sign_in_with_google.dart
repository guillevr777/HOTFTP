import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository repository;

  SignInWithGoogle(this.repository);

  Future<AppUser> execute() => repository.signInWithGoogle();
}
