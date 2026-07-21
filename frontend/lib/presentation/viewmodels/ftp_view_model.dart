import 'package:flutter/material.dart';
import "../../domain/entities/ftp_profile.dart";
import "../../domain/entities/remote_file.dart";
import "../../domain/repositories/ftp_repository.dart";

class FtpViewModel extends ChangeNotifier {
  final FtpRepository repository;
  FtpViewModel({required this.repository});
  List<RemoteFile> remoteFiles = [];
  bool isLoading = false;

  Future<void> loadFiles(String path, FtpProfile profile) async {
    isLoading = true;
    notifyListeners();
    remoteFiles = await repository.getRemoteFiles(path, profile);
    isLoading = false;
    notifyListeners();
  }
}



