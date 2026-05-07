import '../../entities/app_user.dart';
import '../../repositories/auth_repository.dart';

class LinkEmailPassword {
  final AuthRepository repository;

  LinkEmailPassword(this.repository);

  Future<AppUser> execute(String password) =>
      repository.linkEmailPassword(password);
}
