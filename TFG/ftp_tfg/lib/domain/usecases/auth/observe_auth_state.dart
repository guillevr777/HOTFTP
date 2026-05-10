import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../interfaces/i_observe_auth_state_use_case.dart';

class ObserveAuthState implements IObserveAuthStateUseCase {
  final AuthRepository repository;

  ObserveAuthState(this.repository);

  @override
  Stream<AppUser?> execute() => repository.authStateChanges();
}




