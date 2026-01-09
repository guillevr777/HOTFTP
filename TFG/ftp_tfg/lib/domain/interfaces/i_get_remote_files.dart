import '../entities/remote_file.dart';

abstract class IGetRemoteFiles {
  Future<List<RemoteFile>> execute(String path);
}
