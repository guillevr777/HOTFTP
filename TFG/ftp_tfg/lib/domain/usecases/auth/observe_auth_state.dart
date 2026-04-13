import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';

class ObserveAuthState {
  final AuthRepository repository;

  ObserveAuthState(this.repository);

  Stream<AppUser?> execute() => repository.authStateChanges();
}
