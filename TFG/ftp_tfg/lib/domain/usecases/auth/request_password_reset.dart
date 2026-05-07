import '../../repositories/auth_repository.dart';

class RequestPasswordReset {
  final AuthRepository repository;

  RequestPasswordReset(this.repository);

  Future<void> execute(String email) =>
      repository.sendPasswordResetEmail(email);
}
