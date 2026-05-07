import 'package:flutter/material.dart';

import '../../domain/entities/file_version.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../../domain/repositories/monitoring_repository.dart';
import '../../utils/file_utils.dart';

enum RemoteSortField { name, date, size, type }

enum SortDirection { asc, desc }

enum RemoteTypeFilter {
  all,
  folders,
  images,
  videos,
  documents,
  archives,
  others,
}

class BrowserViewModel extends ChangeNotifier {
  final FtpRepository repository;
  final MonitoringRepository monitoringRepository;
  final FtpProfile profile;
  final String ownerId;

  BrowserViewModel({
    required this.repository,
    required this.monitoringRepository,
    required this.profile,
    required this.ownerId,
  });

  List<RemoteFile> remoteFiles = [];
  List<String> localFiles = [];
  bool isLoading = false;
  String? error;
  String currentRemotePath = '/';
  String currentLocalPath = '/storage/emulated/0/Download';
  double uploadProgress = 0;
  double downloadProgress = 0;
  bool isTransferring = false;
  Map<String, String> thumbnails = {};
  String searchQuery = '';
  RemoteSortField sortField = RemoteSortField.name;
  SortDirection sortDirection = SortDirection.asc;
  RemoteTypeFilter typeFilter = RemoteTypeFilter.all;

  List<RemoteFile> get visibleRemoteFiles {
    final filtered = remoteFiles.where((file) {
      final matchesSearch =
          searchQuery.isEmpty ||
          file.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesType = _matchesTypeFilter(file);
      return matchesSearch && matchesType;
    }).toList();

    filtered.sort((a, b) {
      final comparison = switch (sortField) {
        RemoteSortField.name => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        RemoteSortField.date =>
          (a.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            b.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
        RemoteSortField.size => a.size.compareTo(b.size),
        RemoteSortField.type => _typeRank(a).compareTo(_typeRank(b)),
      };
      return sortDirection == SortDirection.asc ? comparison : -comparison;
    });

    return filtered;
  }

  bool _matchesTypeFilter(RemoteFile file) {
    if (typeFilter == RemoteTypeFilter.all) return true;
    if (typeFilter == RemoteTypeFilter.folders) return file.isDirectory;
    if (file.isDirectory) return false;
    return switch (typeFilter) {
      RemoteTypeFilter.images => FileUtils.isImage(file.name),
      RemoteTypeFilter.videos => FileUtils.isVideo(file.name),
      RemoteTypeFilter.documents => FileUtils.isDocument(file.name),
      RemoteTypeFilter.archives => FileUtils.isArchive(file.name),
      RemoteTypeFilter.others =>
        !FileUtils.isImage(file.name) &&
            !FileUtils.isVideo(file.name) &&
            !FileUtils.isDocument(file.name) &&
            !FileUtils.isArchive(file.name),
      _ => true,
    };
  }

  int _typeRank(RemoteFile file) {
    if (file.isDirectory) return 0;
    if (FileUtils.isImage(file.name)) return 1;
    if (FileUtils.isVideo(file.name)) return 2;
    if (FileUtils.isDocument(file.name)) return 3;
    if (FileUtils.isArchive(file.name)) return 4;
    return 5;
  }

  Future<void> loadRemoteFiles([String? path]) async {
    final p = path ?? currentRemotePath;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      remoteFiles = await repository.getRemoteFiles(p, profile);
      currentRemotePath = p;
      await _trackFileVersions();
    } catch (e) {
      error = "Error al listar archivos: $e";
    }
    isLoading = false;
    notifyListeners();
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

  Future<void> navigateRemote(RemoteFile folder) async {
    if (!folder.isDirectory) return;
    await loadRemoteFiles(folder.path);
  }

  Future<void> _trackFileVersions() async {
    if (profile.id == null) return;
    for (final file in remoteFiles.where((file) => !file.isDirectory)) {
      try {
        final latest = await monitoringRepository.getLatestFileVersion(
          ownerId,
          profile.id!,
          file.path,
        );
        final modifiedAt = file.modifiedAt;
        final hasChanged =
            latest == null ||
            latest.size != file.size ||
            latest.modifiedAt?.toIso8601String() !=
                modifiedAt?.toIso8601String();
        if (!hasChanged) continue;
        await monitoringRepository.recordFileVersion(
          FileVersion(
            ownerId: ownerId,
            profileId: profile.id!,
            filePath: file.path,
            fileName: file.name,
            versionNumber: (latest?.versionNumber ?? 0) + 1,
            size: file.size,
            modifiedAt: modifiedAt,
            source: 'remote-scan',
            createdAt: DateTime.now(),
          ),
        );
      } catch (e) {
        debugPrint('Error registrando version de ${file.name}: $e');
      }
    }
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

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setSortField(RemoteSortField value) {
    sortField = value;
    notifyListeners();
  }

  void toggleSortDirection() {
    sortDirection = sortDirection == SortDirection.asc
        ? SortDirection.desc
        : SortDirection.asc;
    notifyListeners();
  }

  void setTypeFilter(RemoteTypeFilter value) {
    typeFilter = value;
    notifyListeners();
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
    if (thumbnails.containsKey(file.path)) return;
    try {
      final localPath = await repository.downloadThumbnail(
        file,
        remotePath,
        profile,
      );
      thumbnails[file.path] = localPath;
      notifyListeners();
    } catch (e) {
      debugPrint("Error cargando miniatura para ${file.name}: $e");
    }
  }

  String formatModifiedAt(RemoteFile file) {
    final date = file.modifiedAt;
    if (date == null) return 'Sin fecha';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
