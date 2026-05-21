class SyncConflict {
  final String fileName;
  final bool localExists;
  final bool remoteExists;

  SyncConflict({
    required this.fileName,
    required this.localExists,
    required this.remoteExists,
  });
}
