import 'package:flutter/material.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/sync_conflict.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/repositories/ftp_repository.dart';

enum SyncMode { push, pull, bidirectional }

class SyncViewModel extends ChangeNotifier {
  final FtpRepository repository;
  final FtpProfile profile;
  SyncViewModel({required this.repository, required this.profile});
  SyncMode syncMode = SyncMode.bidirectional;
  String localPath = '/storage/emulated/0/Download';
  String remotePath = '/';
  bool isSyncing = false;
  bool isDone = false;
  int filesTransferred = 0;
  int filesSkipped = 0;
  String? error;
  List<SyncConflict> conflicts = [];
  List<SyncRecord> history = [];

  void setSyncMode(SyncMode mode) {
    syncMode = mode;
    notifyListeners();
  }

  Future<void> startSync() async {
    isSyncing = true;
    isDone = false;
    filesTransferred = 0;
    filesSkipped = 0;
    error = null;
    conflicts = [];
    notifyListeners();
    try {
      conflicts = await repository.detectConflicts(localPath, remotePath, profile);
      final remoteFiles = await repository.getRemoteFiles(remotePath, profile);
      final localFiles = await repository.getLocalFiles(localPath);
      if (syncMode == SyncMode.push || syncMode == SyncMode.bidirectional) {
        for (final lf in localFiles) {
          final alreadyExists = remoteFiles.any((rf) => rf.name == lf);
          if (!alreadyExists) {
            await repository.uploadFile("$localPath/$lf", remotePath, profile);
            filesTransferred++;
          } else {
            filesSkipped++;
          }
          notifyListeners();
        }
      }
      if (syncMode == SyncMode.pull || syncMode == SyncMode.bidirectional) {
        for (final rf in remoteFiles) {
          if (!rf.isDirectory) {
            final alreadyExists = localFiles.contains(rf.name);
            if (!alreadyExists) {
              await repository.downloadFile(rf, localPath, profile);
              filesTransferred++;
            } else {
              filesSkipped++;
            }
            notifyListeners();
          }
        }
      }
      await repository.saveSyncRecord(SyncRecord(
        profileId: profile.id ?? 0,
        date: DateTime.now(),
        localPath: localPath,
        remotePath: remotePath,
        mode: syncMode.name,
        filesTransferred: filesTransferred,
        filesSkipped: filesSkipped,
      ));
      isDone = true;
    } catch (e) {
      error = "Error durante la sincronizacion: $e";
    }
    isSyncing = false;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    history = await repository.getSyncHistory();
    notifyListeners();
  }
}
