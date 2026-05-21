import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../interfaces/i_sign_in_with_google_use_case.dart';

class SignInWithGoogle implements ISignInWithGoogleUseCase {
  final AuthRepository repository;

  SignInWithGoogle(this.repository);

  @override
  Future<AppUser> execute() => repository.signInWithGoogle();
}




