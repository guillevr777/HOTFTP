import '../repositories/ftp_repository.dart';
import '../interfaces/i_delete_profile_use_case.dart';

class DeleteProfile implements IDeleteProfileUseCase {
  final FtpRepository repository;

  DeleteProfile(this.repository);

  @override
  Future<void> execute(int id, String ownerId) =>
      repository.deleteProfile(id, ownerId);
}




