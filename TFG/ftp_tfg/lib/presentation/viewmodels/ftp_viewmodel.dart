import 'package:flutter/material.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/repositories/ftp_repository.dart';

class FtpViewModel extends ChangeNotifier {
  FtpRepository repository;

  FtpViewModel({required this.repository});

  List<RemoteFile> remoteFiles = [];
  bool isLoading = false;

  Future<void> loadFiles(String path) async {
    isLoading = true;
    notifyListeners();

    remoteFiles = await repository.getRemoteFiles(path);

    isLoading = false;
    notifyListeners();
  }
}
