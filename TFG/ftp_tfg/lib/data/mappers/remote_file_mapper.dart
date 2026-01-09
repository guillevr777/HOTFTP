import '../../domain/entities/remote_file.dart';

class RemoteFileMapper {
  static RemoteFile fromJson(Map<String, dynamic> json) {
    return RemoteFile(
      name: json["name"],
      path: json["path"],
      size: json["size"],
      isDirectory: json["isDirectory"],
      modified: DateTime.parse(json["modified"]),
      lastModified: DateTime.parse(json["lastModified"]),
    );
  }
}
