import '../../domain/entities/remote_file.dart';
import '../../domain/interfaces/i_get_remote_files.dart';
import '../../domain/interfaces/i_connect_ftp.dart';

class FtpViewModel {
  final IConnectFtp connectFtp;
  final IGetRemoteFiles getRemoteFiles;

  List<RemoteFile> remoteFiles = [];

  FtpViewModel({
    required this.connectFtp,
    required this.getRemoteFiles,
  });

  Future<void> loadFiles(String path) async {
    remoteFiles = await getRemoteFiles.execute(path);
  }
}
