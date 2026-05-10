import '../../domain/entities/remote_file.dart';

class RemoteFileMapper {
  static RemoteFile fromMap(Map<String, dynamic> map, String parentPath) {
    final modifiedAt = map['modifyTime'] == null
        ? null
        : DateTime.tryParse(map['modifyTime'] as String);
    final name = map['name'] as String? ?? '';
    final path = parentPath == '/'
        ? '/$name'
        : '${parentPath.endsWith('/') ? parentPath.substring(0, parentPath.length - 1) : parentPath}/$name';
    return RemoteFile(
      name: name,
      path: path,
      size: map['size'] as int? ?? 0,
      isDirectory: map['isDir'] == true,
      modifiedAt: modifiedAt,
    );
  }
}



