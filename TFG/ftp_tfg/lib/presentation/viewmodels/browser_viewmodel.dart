import 'package:flutter/material.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../../utils/file_utils.dart';

class BrowserViewModel extends ChangeNotifier {
  final FtpRepository repository;
  final FtpProfile profile;
  BrowserViewModel({required this.repository, required this.profile});
  List<RemoteFile> remoteFiles = [];
  List<String> localFiles = [];
  bool isLoading = false;
  String? error;
  String currentRemotePath = '/';
  String currentLocalPath = '/storage/emulated/0/Download';
  double uploadProgress = 0;
  double downloadProgress = 0;
  bool isTransferring = false;
  Map<String, String> thumbnails = {}; // fileName -> localPath

  Future<void> loadRemoteFiles([String? path]) async {
    final p = path ?? currentRemotePath;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      remoteFiles = await repository.getRemoteFiles(p, profile);
      currentRemotePath = p;
    } catch (e) {
      error = "Error al listar archivos: $e";
    }
    isLoading = false;
    notifyListeners();
    // Intentar cargar miniaturas de imágenes pequeñas automáticamente
    _loadAllThumbnails();
  }

  Future<void> loadLocalFiles([String? path]) async {
    final p = path ?? currentLocalPath;
    isLoading = true;
    notifyListeners();
    try {
      localFiles = await repository.getLocalFiles(p);
      currentLocalPath = p;
    } catch (e) {
      error = "Error al listar archivos locales: $e";
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> downloadFile(RemoteFile file) async {
    isTransferring = true;
    downloadProgress = 0;
    notifyListeners();
    try {
      await repository.downloadFile(file, currentLocalPath, profile);
      downloadProgress = 1;
    } catch (e) {
      error = "Error al descargar: $e";
    }
    isTransferring = false;
    notifyListeners();
  }

  Future<void> uploadFile(String localFileName) async {
    isTransferring = true;
    uploadProgress = 0;
    notifyListeners();
    try {
      await repository.uploadFile(
        "$currentLocalPath/$localFileName",
        currentRemotePath,
        profile,
      );
      uploadProgress = 1;
      await loadRemoteFiles();
    } catch (e) {
      error = "Error al subir: $e";
    }
    isTransferring = false;
    notifyListeners();
  }

  void navigateRemote(String dirName) {
    final newPath = currentRemotePath == '/'
        ? '/$dirName'
        : '$currentRemotePath/$dirName';
    loadRemoteFiles(newPath);
  }

  void goUpRemote() {
    if (currentRemotePath == '/') return;
    final parts = currentRemotePath.split('/');
    parts.removeLast();
    final newPath = parts.isEmpty || parts.join('/').isEmpty
        ? '/'
        : parts.join('/');
    loadRemoteFiles(newPath);
  }

  Future<void> _loadAllThumbnails() async {
    final path = currentRemotePath;
    for (final file in remoteFiles) {
      if (!file.isDirectory &&
          FileUtils.isImage(file.name) &&
          file.size < 5 * 1024 * 1024) {
        await loadThumbnail(file, path);
      }
    }
  }

  Future<void> loadThumbnail(RemoteFile file, String remotePath) async {
    if (thumbnails.containsKey(file.name)) return;
    try {
      final localPath = await repository.downloadThumbnail(
        file,
        remotePath,
        profile,
      );
      thumbnails[file.name] = localPath;
      notifyListeners();
    } catch (e) {
      debugPrint("Error cargando miniatura para ${file.name}: $e");
    }
  }
}
