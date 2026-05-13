import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../../domain/entities/file_version.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/remote_file.dart';
import '../../utils/file_utils.dart';
import '../../domain/interfaces/i_download_file_use_case.dart';
import '../../domain/interfaces/i_download_thumbnail_use_case.dart';
import '../../domain/interfaces/i_get_latest_file_version_use_case.dart';
import '../../domain/interfaces/i_get_local_files_use_case.dart';
import '../../domain/interfaces/i_get_remote_files_use_case.dart';
import '../../domain/interfaces/i_record_file_version_use_case.dart';
import '../../domain/interfaces/i_upload_file_use_case.dart';

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
  final IGetRemoteFilesUseCase getRemoteFiles;
  final IGetLocalFilesUseCase getLocalFiles;
  final IDownloadFileUseCase downloadFileUseCase;
  final IUploadFileUseCase uploadFileUseCase;
  final IDownloadThumbnailUseCase downloadThumbnailUseCase;
  final IGetLatestFileVersionUseCase getLatestFileVersion;
  final IRecordFileVersionUseCase recordFileVersion;
  final FtpProfile profile;
  final String ownerId;

  BrowserViewModel({
    required this.getRemoteFiles,
    required this.getLocalFiles,
    required this.downloadFileUseCase,
    required this.uploadFileUseCase,
    required this.downloadThumbnailUseCase,
    required this.getLatestFileVersion,
    required this.recordFileVersion,
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
  final Map<String, List<RemoteFile>> _remoteCache = {};
  final Queue<_ThumbnailRequest> _thumbnailQueue = Queue<_ThumbnailRequest>();
  final Set<String> _queuedThumbnailPaths = {};
  final Set<String> _loadingThumbnailPaths = {};
  int _activeThumbnailLoads = 0;
  static const int _maxConcurrentThumbnailLoads = 2;
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

  Future<void> loadRemoteFiles({
    String? path,
    bool forceRefresh = false,
  }) async {
    final p = path ?? currentRemotePath;
    currentRemotePath = p;
    final cached = _remoteCache[p];
    if (cached != null && !forceRefresh) {
      remoteFiles = List<RemoteFile>.of(cached);
      error = null;
      isLoading = false;
      notifyListeners();
      unawaited(_refreshRemoteFiles(p));
      return;
    }

    isLoading = true;
    error = null;
    notifyListeners();
    await _refreshRemoteFiles(p);
    isLoading = false;
    notifyListeners();
  }

  void resetFilters() {
    searchQuery = '';
    sortField = RemoteSortField.name;
    sortDirection = SortDirection.asc;
    typeFilter = RemoteTypeFilter.all;
    notifyListeners();
  }

  Future<void> loadLocalFiles([String? path]) async {
    final p = path ?? currentLocalPath;
    isLoading = true;
    notifyListeners();
    try {
      localFiles = await getLocalFiles.execute(p);
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
      await downloadFileUseCase.execute(file, currentLocalPath, profile);
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
      await uploadFileUseCase.execute(
        "$currentLocalPath/$localFileName",
        currentRemotePath,
        profile,
      );
      uploadProgress = 1;
      _remoteCache.remove(currentRemotePath);
      await loadRemoteFiles();
    } catch (e) {
      error = "Error al subir: $e";
    }
    isTransferring = false;
    notifyListeners();
  }

  Future<void> navigateRemote(RemoteFile folder) async {
    if (!folder.isDirectory) return;
    await loadRemoteFiles(path: folder.path);
  }

  Future<void> _refreshRemoteFiles(String path) async {
    try {
      final freshFiles = await getRemoteFiles.execute(path, profile);
      if (currentRemotePath != path) return;
      remoteFiles = freshFiles;
      _remoteCache[path] = List<RemoteFile>.of(freshFiles);
      // Keep the first paint fast; sync metadata in the background.
      unawaited(_trackFileVersions());
      notifyListeners();
    } catch (e) {
      remoteFiles = [];
      error = "Error al listar archivos: $e";
      debugPrint('HOTFTP: loadRemoteFiles failed for $path -> $e');
      notifyListeners();
    }
  }

  Future<void> _trackFileVersions() async {
    if (profile.id == null) return;
    for (final file in remoteFiles.where((file) => !file.isDirectory)) {
      try {
        final latest = await getLatestFileVersion.execute(
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
        await recordFileVersion.execute(
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
    loadRemoteFiles(path: newPath);
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

  void requestThumbnail(RemoteFile file, String remotePath) {
    if (!FileUtils.isImage(file.name)) return;
    if (thumbnails.containsKey(file.path)) return;
    if (_queuedThumbnailPaths.contains(file.path) ||
        _loadingThumbnailPaths.contains(file.path)) {
      return;
    }

    _queuedThumbnailPaths.add(file.path);
    _thumbnailQueue.add(_ThumbnailRequest(file: file, remotePath: remotePath));
    _pumpThumbnailQueue();
  }

  Future<void> loadThumbnail(RemoteFile file, String remotePath) async {
    requestThumbnail(file, remotePath);
  }

  void _pumpThumbnailQueue() {
    while (_activeThumbnailLoads < _maxConcurrentThumbnailLoads &&
        _thumbnailQueue.isNotEmpty) {
      final request = _thumbnailQueue.removeFirst();
      _queuedThumbnailPaths.remove(request.file.path);
      _loadingThumbnailPaths.add(request.file.path);
      _activeThumbnailLoads++;
      unawaited(_runThumbnailRequest(request));
    }
  }

  Future<void> _runThumbnailRequest(_ThumbnailRequest request) async {
    try {
      final localPath = await downloadThumbnailUseCase.execute(
        request.file,
        request.remotePath,
        profile,
      );
      thumbnails[request.file.path] = localPath;
      notifyListeners();
    } catch (e) {
      debugPrint("Error cargando miniatura para ${request.file.name}: $e");
    } finally {
      _loadingThumbnailPaths.remove(request.file.path);
      if (_activeThumbnailLoads > 0) {
        _activeThumbnailLoads--;
      }
      _pumpThumbnailQueue();
    }
  }

  String formatModifiedAt(RemoteFile file) {
    final date = file.modifiedAt;
    if (date == null) return 'Sin fecha';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _ThumbnailRequest {
  final RemoteFile file;
  final String remotePath;

  const _ThumbnailRequest({
    required this.file,
    required this.remotePath,
  });
}
