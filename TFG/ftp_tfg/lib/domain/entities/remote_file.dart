class RemoteFile {
  final String name;
  final String path;
  final int size;
  final DateTime lastModified;
  final bool isDirectory;

  const RemoteFile({
    required this.name,
    required this.path,
    required this.size,
    required this.lastModified,
    required this.isDirectory, required DateTime modified,
  });
}
