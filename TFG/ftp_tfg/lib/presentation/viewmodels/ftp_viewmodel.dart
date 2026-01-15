import 'package:flutter/foundation.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/interfaces/i_get_remote_files.dart';

class FtpViewModel extends ChangeNotifier {
  final IGetRemoteFiles getRemoteFiles;

  List<RemoteFile> remoteFiles = [];
  bool isLoading = false;

  FtpViewModel(this.getRemoteFiles);

  Future<void> loadFiles(String path) async {
    isLoading = true;
    notifyListeners();

    remoteFiles = await getRemoteFiles.execute(path);

    isLoading = false;
    notifyListeners();
  }
}
