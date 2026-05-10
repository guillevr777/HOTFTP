import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../interfaces/i_restore_session_use_case.dart';

class RestoreSession implements IRestoreSessionUseCase {
  final AuthRepository repository;

  RestoreSession(this.repository);

  @override
  Future<AppUser?> execute() => repository.currentUser();
}




