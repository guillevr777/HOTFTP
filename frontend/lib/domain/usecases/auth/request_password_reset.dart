import '../../repositories/auth_repository.dart';
import '../../interfaces/i_request_password_reset_use_case.dart';

class RequestPasswordReset implements IRequestPasswordResetUseCase {
  final AuthRepository repository;

  RequestPasswordReset(this.repository);

  @override
  Future<void> execute(String email) =>
      repository.sendPasswordResetEmail(email);
}




