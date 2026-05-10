import '../../entities/app_user.dart';
import '../../repositories/auth_repository.dart';
import '../../interfaces/i_link_email_password_use_case.dart';

class LinkEmailPassword implements ILinkEmailPasswordUseCase {
  final AuthRepository repository;

  LinkEmailPassword(this.repository);

  @override
  Future<AppUser> execute(String password) =>
      repository.linkEmailPassword(password);
}




