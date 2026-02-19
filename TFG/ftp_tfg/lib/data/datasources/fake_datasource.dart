import "../interfaces/ftp_datasource.dart";

class FakeFtpDatasource implements FtpDatasource {
  @override
  Future<List<Map<String, dynamic>>> listRemoteFiles(
    String path,
    Map<String, dynamic> config,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {"name": "Documentos", "size": 0, "isDir": true},
      {"name": "Imagenes", "size": 0, "isDir": true},
      {"name": "notas.txt", "size": 1204, "isDir": false},
      {"name": "configuración.xml", "size": 450, "isDir": false},
    ];
  }

  @override
  Future<List<String>> listLocalFiles(String path) async {
    return ["archivo_local.pdf", "foto.jpg", "proyecto.zip"];
  }

  @override
  Future<void> uploadFile(
    String localFilePath,
    String remotePath,
    Map<String, dynamic> config,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> downloadFile(
    String remoteFileName,
    String localPath,
    Map<String, dynamic> config,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> downloadFileToPath(
    String remoteFileName,
    String remoteDirectory,
    String targetLocalPath,
    Map<String, dynamic> config,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<bool> testConnection(Map<String, dynamic> profile) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return profile["host"] != null && profile["host"].isNotEmpty;
  }
}
