import 'package:flutter/material.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/usecases/get_remote_files.dart';
import '../../data/datasources/ftp_real_datasource.dart';

class FtpViewModel extends ChangeNotifier {
  final GetRemoteFiles getRemoteFiles;

  List<RemoteFile> remoteFiles = [];
  bool isLoading = false;
  FtpRealDatasource? _datasource;

  FtpViewModel({required this.getRemoteFiles});

  /// Conectar a un servidor FTP
  Future<bool> connect({
  required String host,
  int port = 21,
  required String username,
  required String password,
}) async {
  try {
    print("Intentando conectar a $host:$port con usuario $username");

    _datasource = FtpRealDatasource(
      host: host,
      user: username,
      pass: password,
      port: port,
    );

    // Probar conexión real
    await _datasource!.listRemoteFiles('/');

    print("Conexión FTP correcta");
    return true;
  } catch (e, stackTrace) {
    print("ERROR DE CONEXIÓN FTP");
    print(e);
    print(stackTrace);
    return false;
  }
}


  /// Cargar archivos remotos
  Future<void> loadFiles(String path) async {
    if (_datasource == null) return;

    isLoading = true;
    notifyListeners();
    final repo = getRemoteFiles.repository; // Usamos el repository actual
    remoteFiles = await repo.getRemoteFiles(path);
    isLoading = false;
    notifyListeners();
  }
}
