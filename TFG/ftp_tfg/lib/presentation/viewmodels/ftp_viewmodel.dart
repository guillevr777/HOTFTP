import 'package:flutter/foundation.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/interfaces/i_connect_ftp.dart';
import '../../domain/interfaces/i_get_remote_files.dart';

class FtpViewModel extends ChangeNotifier {
  final IConnectFtp connectFtp;
  final IGetRemoteFiles getRemoteFiles;

  List<RemoteFile> remoteFiles = [];
  bool isConnected = false;
  bool isLoading = false;

  FtpViewModel({
    required this.connectFtp,
    required this.getRemoteFiles,
  });

  Future<void> connect(FtpProfile profile) async {
    isLoading = true;
    notifyListeners();

    isConnected = await connectFtp.execute(profile);

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadFiles(String path) async {
    if (!isConnected) return;

    isLoading = true;
    notifyListeners();

    remoteFiles = await getRemoteFiles.execute(path);

    isLoading = false;
    notifyListeners();
  }
}
