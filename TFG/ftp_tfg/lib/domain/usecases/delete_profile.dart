import '../repositories/ftp_repository.dart';

class DeleteProfile {
  final FtpRepository repository;

  DeleteProfile(this.repository);

  Future<void> execute(int id, String ownerId) =>
      repository.deleteProfile(id, ownerId);
}
