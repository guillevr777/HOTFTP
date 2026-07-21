import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../interfaces/i_register_user_use_case.dart';

class RegisterUser implements IRegisterUserUseCase {
  final AuthRepository repository;

  RegisterUser(this.repository);

  @override
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




