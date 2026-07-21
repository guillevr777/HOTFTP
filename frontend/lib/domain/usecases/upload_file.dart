import "../entities/ftp_profile.dart";
import "../repositories/ftp_repository.dart";
import '../interfaces/i_upload_file_use_case.dart';

class UploadFile implements IUploadFileUseCase {
  final FtpRepository repository;
  UploadFile(this.repository);
  @override
  Future<void> execute(String localPath, String remotePath, FtpProfile profile) =>
      repository.uploadFile(localPath, remotePath, profile);
}




