import '../../repositories/auth_repository.dart';
import '../../interfaces/i_logout_user_use_case.dart';

class LogoutUser implements ILogoutUserUseCase {
  final AuthRepository repository;

  LogoutUser(this.repository);

  @override
  Future<void> execute() => repository.signOut();
}




