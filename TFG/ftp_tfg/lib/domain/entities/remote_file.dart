class RemoteFile {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;

  const RemoteFile({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
  });
}
