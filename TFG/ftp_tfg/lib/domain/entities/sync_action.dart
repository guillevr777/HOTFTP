enum SyncType { upload, download, bidirectional }

class SyncAction {
  final String localPath;
  final String remotePath;
  final SyncType type;

  SyncAction({
    required this.localPath,
    required this.remotePath,
    required this.type,
  });
}
