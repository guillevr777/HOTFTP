class RemoteFile {
  final String name;
  final String path;
  final int size;
  final bool isDirectory;
  final DateTime? modifiedAt;

  RemoteFile({
    required this.name,
    required this.path,
    required this.size,
    required this.isDirectory,
    this.modifiedAt,
  });
}

