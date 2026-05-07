import '../../entities/app_user.dart';
import '../../repositories/auth_repository.dart';

class UpdateDisplayName {
  final AuthRepository repository;

  UpdateDisplayName(this.repository);

  Future<AppUser> execute(String displayName) =>
      repository.updateDisplayName(displayName);
}
