import '../../entities/app_user.dart';
import '../../repositories/auth_repository.dart';
import '../../interfaces/i_update_display_name_use_case.dart';

class UpdateDisplayName implements IUpdateDisplayNameUseCase {
  final AuthRepository repository;

  UpdateDisplayName(this.repository);

  @override
  Future<AppUser> execute(String displayName) =>
      repository.updateDisplayName(displayName);
}




