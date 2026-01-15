import 'package:flutter/foundation.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/entities/sync_action.dart';
import '../../domain/interfaces/i_connect_ftp.dart';
import '../../domain/interfaces/i_get_remote_files.dart';
import '../../domain/interfaces/i_sync_folder.dart';

class FtpViewModel extends ChangeNotifier {
  final IConnectFtp connectFtp;
  final IGetRemoteFiles getRemoteFiles;
  final ISyncFolder syncFolder;

  List<RemoteFile> remoteFiles = [];
  bool isConnected = false;
  bool isLoading = false;
  String? errorMessage;

  FtpViewModel({
    required this.connectFtp,
    required this.getRemoteFiles,
    required this.syncFolder,
  });

  Future<void> connect(FtpProfile profile) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      isConnected = await connectFtp.execute(profile);
    } catch (e) {
      isConnected = false;
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadFiles(String path) async {
    if (!isConnected) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      remoteFiles = await getRemoteFiles.execute(path);
    } catch (e) {
      remoteFiles = [];
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> sync(SyncAction action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await syncFolder.execute(action);
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  void disconnect() {
    isConnected = false;
    remoteFiles = [];
    errorMessage = null;
    notifyListeners();
  }
}
