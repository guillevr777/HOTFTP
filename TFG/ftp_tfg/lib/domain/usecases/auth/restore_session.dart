import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';

class RestoreSession {
  final AuthRepository repository;

  RestoreSession(this.repository);

  Future<AppUser?> execute() => repository.currentUser();
}
