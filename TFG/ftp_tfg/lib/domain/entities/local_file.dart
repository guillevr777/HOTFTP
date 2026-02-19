class LocalFile {
  final String name;
  final String path;
  final int size;
  final bool isDirectory;
  final DateTime? lastModified;

  LocalFile({
    required this.name,
    required this.path,
    required this.size,
    required this.isDirectory,
    this.lastModified,
  });
}
