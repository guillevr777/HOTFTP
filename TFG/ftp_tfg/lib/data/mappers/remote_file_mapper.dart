import '../../domain/entities/remote_file.dart';

class RemoteFileMapper {
  static RemoteFile fromMap(Map<String, dynamic> map) {
    return RemoteFile(
      name: map['name'],
      path: map['path'],
      isDirectory: map['isDirectory'],
      size: map['size'],
    );
  }
}
