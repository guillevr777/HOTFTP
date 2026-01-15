import 'package:flutter/foundation.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/interfaces/i_connect_ftp.dart';
import '../../domain/interfaces/i_get_remote_files.dart';

class FtpViewModel extends ChangeNotifier {
  final IConnectFtp connectFtp;
  final IGetRemoteFiles getRemoteFiles;

  // 🔹 Estados de la UI
  List<RemoteFile> remoteFiles = [];
  bool isConnected = false;
  bool isLoading = false;
  String? errorMessage; // Para mostrar errores en UI

  FtpViewModel({
    required this.connectFtp,
    required this.getRemoteFiles,
  });

  // 🔹 Conectar al FTP
  Future<void> connect(FtpProfile profile) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      isConnected = await connectFtp.execute(profile);
    } catch (e) {
      isConnected = false;
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  // 🔹 Cargar archivos remotos
  Future<void> loadFiles(String path) async {
    if (!isConnected) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      remoteFiles = await getRemoteFiles.execute(path);
    } catch (e) {
      remoteFiles = [];
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  // 🔹 Resetear estado de conexión (opcional)
  void disconnect() {
    isConnected = false;
    remoteFiles = [];
    errorMessage = null;
    notifyListeners();
  }
}
