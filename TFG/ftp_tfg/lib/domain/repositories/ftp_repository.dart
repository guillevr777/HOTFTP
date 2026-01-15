import '../entities/remote_file.dart';

abstract class FtpRepository {
  Future<List<RemoteFile>> getRemoteFiles(String path);
}
