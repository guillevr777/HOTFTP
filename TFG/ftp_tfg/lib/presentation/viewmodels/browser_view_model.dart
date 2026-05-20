import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

import '../../domain/entities/file_version.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/local_file.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/interfaces/i_download_file_use_case.dart';
import '../../domain/interfaces/i_download_thumbnail_use_case.dart';
import '../../domain/interfaces/i_get_latest_file_version_use_case.dart';
import '../../domain/interfaces/i_get_local_file_details_use_case.dart';
import '../../domain/interfaces/i_get_local_files_use_case.dart';
import '../../domain/interfaces/i_get_remote_files_use_case.dart';
import '../../domain/interfaces/i_record_file_version_use_case.dart';
import '../../domain/interfaces/i_upload_file_use_case.dart';
import '../../utils/file_utils.dart';
import '../../utils/local_download_manifest_store.dart';

enum BrowserDestination { remote, local }

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

enum RemoteFileViewMode { list, grid }

enum RemoteGridDensity { compact, medium, large }

String _defaultLocalPath() {
  if (kIsWeb) return '/';
  if (Platform.isAndroid || Platform.isIOS) {
    return '/storage/emulated/0/Download';
  }
  return Directory.current.path;
}

class BrowserViewModel extends ChangeNotifier {
  final IGetRemoteFilesUseCase getRemoteFiles;
  final IGetLocalFilesUseCase getLocalFiles;
  final IGetLocalFileDetailsUseCase getLocalFileDetails;
  final IDownloadFileUseCase downloadFileUseCase;
  final IUploadFileUseCase uploadFileUseCase;
  final IDownloadThumbnailUseCase downloadThumbnailUseCase;
  final IGetLatestFileVersionUseCase getLatestFileVersion;
  final IRecordFileVersionUseCase recordFileVersion;
  final FtpProfile profile;
  final String ownerId;

  BrowserDestination destination = BrowserDestination.remote;
  List<RemoteFile> remoteFiles = [];
  List<LocalFile> localFiles = [];
  bool isLoading = false;
  String? error;
  String currentRemotePath = '/';
  String currentLocalPath = _defaultLocalPath();
  double uploadProgress = 0;
  double downloadProgress = 0;
  bool isTransferring = false;
  Map<String, String> thumbnails = {};
  final Map<String, List<RemoteFile>> _remoteCache = {};
  final Map<String, List<LocalFile>> _localCache = {};
  final List<_ThumbnailRequest> _priorityThumbnailQueue = [];
  final List<_ThumbnailRequest> _thumbnailQueue = [];
  final Set<String> _queuedThumbnailPaths = {};
  final Set<String> _loadingThumbnailPaths = {};
  int _activeThumbnailLoads = 0;
  static const int _maxConcurrentThumbnailLoads = 6;
  static const int _visibleRemoteFileBatchSize = 50;
  int _visibleRemoteFileCount = _visibleRemoteFileBatchSize;
  int _visibleLocalFileCount = _visibleRemoteFileBatchSize;
  List<RemoteFile>? _visibleRemoteFilesCache;
  List<LocalFile>? _visibleLocalFilesCache;
  String searchQuery = '';
  RemoteSortField sortField = RemoteSortField.name;
  SortDirection sortDirection = SortDirection.asc;
  RemoteTypeFilter typeFilter = RemoteTypeFilter.all;
  RemoteFileViewMode displayMode = RemoteFileViewMode.grid;
  RemoteGridDensity gridDensity = RemoteGridDensity.medium;
  bool _disposed = false;

  BrowserViewModel({
    required this.getRemoteFiles,
    required this.getLocalFiles,
    required this.getLocalFileDetails,
    required this.downloadFileUseCase,
    required this.uploadFileUseCase,
    required this.downloadThumbnailUseCase,
    required this.getLatestFileVersion,
    required this.recordFileVersion,
    required this.profile,
    required this.ownerId,
  });

  bool get isLocalDestination => destination == BrowserDestination.local;
  bool get isRemoteDestination => destination == BrowserDestination.remote;
  String get currentPath =>
      isLocalDestination ? currentLocalPath : currentRemotePath;

  List<RemoteFile> get visibleRemoteFiles {
    final cached = _visibleRemoteFilesCache;
    if (cached != null) return cached;

    final filtered = remoteFiles.where((file) {
      final matchesSearch =
          searchQuery.isEmpty ||
          file.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesType = _matchesTypeFilter(
        name: file.name,
        isDirectory: file.isDirectory,
      );
      return matchesSearch && matchesType;
    }).toList();

    filtered.sort(
      (a, b) => _compareEntries(
        nameA: a.name,
        nameB: b.name,
        sizeA: a.size,
        sizeB: b.size,
        modifiedA: a.modifiedAt,
        modifiedB: b.modifiedAt,
        isDirectoryA: a.isDirectory,
        isDirectoryB: b.isDirectory,
      ),
    );

    _visibleRemoteFilesCache = filtered;
    return filtered;
  }

  List<LocalFile> get visibleLocalFiles {
    final cached = _visibleLocalFilesCache;
    if (cached != null) return cached;

    final filtered = localFiles.where((file) {
      final matchesSearch =
          searchQuery.isEmpty ||
          file.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesType = _matchesTypeFilter(
        name: file.name,
        isDirectory: file.isDirectory,
      );
      return matchesSearch && matchesType;
    }).toList();

    filtered.sort(
      (a, b) => _compareEntries(
        nameA: a.name,
        nameB: b.name,
        sizeA: a.size,
        sizeB: b.size,
        modifiedA: a.lastModified,
        modifiedB: b.lastModified,
        isDirectoryA: a.isDirectory,
        isDirectoryB: b.isDirectory,
      ),
    );

    _visibleLocalFilesCache = filtered;
    return filtered;
  }

  List<RemoteFile> get displayedRemoteFiles {
    final files = visibleRemoteFiles;
    final limit = _visibleRemoteFileCount < files.length
        ? _visibleRemoteFileCount
        : files.length;
    return files.take(limit).toList(growable: false);
  }

  List<LocalFile> get displayedLocalFiles {
    final files = visibleLocalFiles;
    final limit = _visibleLocalFileCount < files.length
        ? _visibleLocalFileCount
        : files.length;
    return files.take(limit).toList(growable: false);
  }

  bool get hasMoreRemoteFiles =>
      _visibleRemoteFileCount < visibleRemoteFiles.length;

  bool get hasMoreLocalFiles =>
      _visibleLocalFileCount < visibleLocalFiles.length;

  bool _matchesTypeFilter({required String name, required bool isDirectory}) {
    if (typeFilter == RemoteTypeFilter.all) return true;
    if (typeFilter == RemoteTypeFilter.folders) return isDirectory;
    if (isDirectory) return false;
    return switch (typeFilter) {
      RemoteTypeFilter.images => FileUtils.isImage(name),
      RemoteTypeFilter.videos => FileUtils.isVideo(name),
      RemoteTypeFilter.documents => FileUtils.isDocument(name),
      RemoteTypeFilter.archives => FileUtils.isArchive(name),
      RemoteTypeFilter.others =>
        !FileUtils.isImage(name) &&
            !FileUtils.isVideo(name) &&
            !FileUtils.isDocument(name) &&
            !FileUtils.isArchive(name),
      _ => true,
    };
  }

  int _compareEntries({
    required String nameA,
    required String nameB,
    required int sizeA,
    required int sizeB,
    required DateTime? modifiedA,
    required DateTime? modifiedB,
    required bool isDirectoryA,
    required bool isDirectoryB,
  }) {
    final comparison = switch (sortField) {
      RemoteSortField.name => nameA.toLowerCase().compareTo(
        nameB.toLowerCase(),
      ),
      RemoteSortField.date =>
        (modifiedA ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          modifiedB ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
      RemoteSortField.size => sizeA.compareTo(sizeB),
      RemoteSortField.type => _typeRank(
        nameA,
        isDirectoryA,
      ).compareTo(_typeRank(nameB, isDirectoryB)),
    };
    return sortDirection == SortDirection.asc ? comparison : -comparison;
  }

  int _typeRank(String fileName, bool isDirectory) {
    if (isDirectory) return 0;
    if (FileUtils.isImage(fileName)) return 1;
    if (FileUtils.isVideo(fileName)) return 2;
    if (FileUtils.isDocument(fileName)) return 3;
    if (FileUtils.isArchive(fileName)) return 4;
    return 5;
  }

  Future<void> setDestination(BrowserDestination value) async {
    if (destination == value) return;
    destination = value;
    _resetVisibleRemoteFilesPagination();
    _resetVisibleLocalFilesPagination();
    _invalidateVisibleRemoteFilesCache();
    _invalidateVisibleLocalFilesCache();
    notifyListeners();

    if (value == BrowserDestination.remote && remoteFiles.isEmpty) {
      await loadRemoteFiles();
    } else if (value == BrowserDestination.local && localFiles.isEmpty) {
      await loadLocalFiles();
    }
  }

  Future<void> loadRemoteFiles({
    String? path,
    bool forceRefresh = false,
  }) async {
    final normalizedPath = _normalizeRemotePath(path ?? currentRemotePath);
    currentRemotePath = normalizedPath;
    _resetVisibleRemoteFilesPagination();
    final cached = _remoteCache[normalizedPath];
    if (cached != null && !forceRefresh) {
      remoteFiles = List<RemoteFile>.of(cached);
      _invalidateVisibleRemoteFilesCache();
      error = null;
      isLoading = false;
      _notifyIfActive();
      unawaited(_refreshRemoteFiles(normalizedPath));
      return;
    }

    isLoading = true;
    error = null;
    _notifyIfActive();
    await _refreshRemoteFiles(normalizedPath);
    isLoading = false;
    _notifyIfActive();
  }

  Future<void> loadLocalFiles({String? path, bool forceRefresh = false}) async {
    final normalizedPath = _normalizeLocalPath(path ?? currentLocalPath);
    currentLocalPath = normalizedPath;
    _resetVisibleLocalFilesPagination();
    final cached = _localCache[normalizedPath];
    if (cached != null && !forceRefresh) {
      localFiles = List<LocalFile>.of(cached);
      _invalidateVisibleLocalFilesCache();
      error = null;
      isLoading = false;
      _notifyIfActive();
      unawaited(_refreshLocalFiles(normalizedPath));
      return;
    }

    isLoading = true;
    error = null;
    _notifyIfActive();
    await _refreshLocalFiles(normalizedPath);
    isLoading = false;
    _notifyIfActive();
  }

  void resetFilters() {
    searchQuery = '';
    sortField = RemoteSortField.name;
    sortDirection = SortDirection.asc;
    typeFilter = RemoteTypeFilter.all;
    _resetVisibleRemoteFilesPagination();
    _resetVisibleLocalFilesPagination();
    _invalidateVisibleRemoteFilesCache();
    _invalidateVisibleLocalFilesCache();
    notifyListeners();
  }

  Future<void> downloadFile(
    RemoteFile file, {
    void Function(double progress)? onProgress,
  }) async {
    isTransferring = true;
    downloadProgress = 0;
    error = null;
    notifyListeners();
    try {
      await downloadFileUseCase.execute(
        file,
        currentLocalPath,
        profile,
        onProgress: (progress) {
          downloadProgress = progress.clamp(0.0, 1.0).toDouble();
          onProgress?.call(downloadProgress);
          _notifyIfActive();
        },
      );
      await LocalDownloadManifestStore.save(
        LocalDownloadManifest(
          localPath: p.join(currentLocalPath, file.name),
          remoteFile: file,
          profile: profile,
        ),
      );
      downloadProgress = 1;
    } catch (e) {
      error = 'Error al descargar: $e';
    }
    isTransferring = false;
    notifyListeners();
  }

  Future<bool> repairLocalFile(
    LocalFile file, {
    bool refreshAfterRepair = true,
  }) async {
    if (file.isDirectory) return false;
    final manifest = await LocalDownloadManifestStore.read(file.path);
    if (manifest == null) return false;

    final target = File(file.path);
    try {
      if (await target.exists()) {
        await target.delete();
      }
    } catch (e) {
      debugPrint('HOTFTP: failed deleting corrupt file ${file.path} -> $e');
    }

    try {
      await downloadFileUseCase.execute(
        manifest.remoteFile,
        p.dirname(file.path),
        manifest.profile,
      );
      await LocalDownloadManifestStore.save(
        LocalDownloadManifest(
          localPath: file.path,
          remoteFile: manifest.remoteFile,
          profile: manifest.profile,
        ),
      );
      if (refreshAfterRepair && isLocalDestination) {
        await _refreshLocalFiles(currentLocalPath);
      }
      return true;
    } catch (e) {
      debugPrint('HOTFTP: repairLocalFile failed for ${file.path} -> $e');
      return false;
    }
  }

  Future<void> uploadFile(String localFileName) async {
    isTransferring = true;
    uploadProgress = 0;
    error = null;
    notifyListeners();
    try {
      await uploadFileUseCase.execute(
        p.join(currentLocalPath, localFileName),
        currentRemotePath,
        profile,
      );
      uploadProgress = 1;
      _remoteCache.remove(currentRemotePath);
      await loadRemoteFiles();
    } catch (e) {
      error = 'Error al subir: $e';
    }
    isTransferring = false;
    notifyListeners();
  }

  Future<void> navigateRemote(RemoteFile folder) async {
    if (!folder.isDirectory) return;
    await loadRemoteFiles(path: folder.path);
  }

  Future<void> navigateLocal(LocalFile folder) async {
    if (!folder.isDirectory) return;
    await loadLocalFiles(path: folder.path);
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

  void goUpLocal() {
    final normalized = _normalizeLocalPath(currentLocalPath);
    final parent = p.dirname(normalized);
    if (parent.isEmpty || parent == normalized) return;
    loadLocalFiles(path: parent);
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    _resetVisibleRemoteFilesPagination();
    _resetVisibleLocalFilesPagination();
    _invalidateVisibleRemoteFilesCache();
    _invalidateVisibleLocalFilesCache();
    notifyListeners();
  }

  void setSortField(RemoteSortField value) {
    sortField = value;
    _resetVisibleRemoteFilesPagination();
    _resetVisibleLocalFilesPagination();
    _invalidateVisibleRemoteFilesCache();
    _invalidateVisibleLocalFilesCache();
    notifyListeners();
  }

  void toggleSortDirection() {
    sortDirection = sortDirection == SortDirection.asc
        ? SortDirection.desc
        : SortDirection.asc;
    _resetVisibleRemoteFilesPagination();
    _resetVisibleLocalFilesPagination();
    _invalidateVisibleRemoteFilesCache();
    _invalidateVisibleLocalFilesCache();
    notifyListeners();
  }

  void setTypeFilter(RemoteTypeFilter value) {
    typeFilter = value;
    _resetVisibleRemoteFilesPagination();
    _resetVisibleLocalFilesPagination();
    _invalidateVisibleRemoteFilesCache();
    _invalidateVisibleLocalFilesCache();
    notifyListeners();
  }

  void setDisplayMode(RemoteFileViewMode value) {
    if (displayMode == value) return;
    displayMode = value;
    notifyListeners();
  }

  void toggleDisplayMode() {
    setDisplayMode(
      displayMode == RemoteFileViewMode.list
          ? RemoteFileViewMode.grid
          : RemoteFileViewMode.list,
    );
  }

  void setGridDensity(RemoteGridDensity value) {
    if (gridDensity == value) return;
    gridDensity = value;
    notifyListeners();
  }

  void loadMoreVisibleRemoteFiles() {
    if (!hasMoreRemoteFiles) return;
    _visibleRemoteFileCount += _visibleRemoteFileBatchSize;
    notifyListeners();
  }

  void loadMoreVisibleLocalFiles() {
    if (!hasMoreLocalFiles) return;
    _visibleLocalFileCount += _visibleRemoteFileBatchSize;
    notifyListeners();
  }

  void prioritizeVisibleThumbnails(
    Iterable<RemoteFile> files,
    String remotePath,
  ) {
    for (final file in files) {
      if (file.isDirectory) continue;
      if (!FileUtils.isImage(file.name) && !FileUtils.isVideo(file.name)) {
        continue;
      }
      requestThumbnail(file, remotePath, highPriority: true);
    }
  }

  void requestThumbnail(
    RemoteFile file,
    String remotePath, {
    bool highPriority = false,
  }) {
    final isImage = FileUtils.isImage(file.name);
    final isVideo = FileUtils.isVideo(file.name);
    if (!isImage && !isVideo) return;
    if (isVideo &&
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }
    if (thumbnails.containsKey(file.path)) return;
    if (_queuedThumbnailPaths.contains(file.path) ||
        _loadingThumbnailPaths.contains(file.path)) {
      if (highPriority) {
        _promoteQueuedThumbnail(file, remotePath);
      }
      return;
    }

    _queuedThumbnailPaths.add(file.path);
    final request = _ThumbnailRequest(file: file, remotePath: remotePath);
    if (highPriority) {
      _priorityThumbnailQueue.add(request);
    } else {
      _thumbnailQueue.add(request);
    }
    _pumpThumbnailQueue();
  }

  void invalidateThumbnail(String filePath) {
    if (thumbnails.remove(filePath) != null) {
      _notifyIfActive();
    }
  }

  Future<void> loadThumbnail(RemoteFile file, String remotePath) async {
    requestThumbnail(file, remotePath);
  }

  void _pumpThumbnailQueue() {
    while (_activeThumbnailLoads < _maxConcurrentThumbnailLoads) {
      final request = _priorityThumbnailQueue.isNotEmpty
          ? _priorityThumbnailQueue.removeAt(0)
          : _thumbnailQueue.isNotEmpty
          ? _thumbnailQueue.removeAt(0)
          : null;
      if (request == null) return;
      _queuedThumbnailPaths.remove(request.file.path);
      _loadingThumbnailPaths.add(request.file.path);
      _activeThumbnailLoads++;
      unawaited(_runThumbnailRequest(request));
    }
  }

  void _promoteQueuedThumbnail(RemoteFile file, String remotePath) {
    final promoted = _ThumbnailRequest(file: file, remotePath: remotePath);
    _thumbnailQueue.removeWhere((request) => request.file.path == file.path);
    if (_priorityThumbnailQueue.any(
      (request) => request.file.path == file.path,
    )) {
      return;
    }
    _priorityThumbnailQueue.add(promoted);
    _pumpThumbnailQueue();
  }

  Future<void> _runThumbnailRequest(_ThumbnailRequest request) async {
    try {
      final localPath = await downloadThumbnailUseCase.execute(
        request.file,
        request.remotePath,
        profile,
      );
      thumbnails[request.file.path] = localPath;
      _notifyIfActive();
    } catch (e) {
      debugPrint('Error cargando miniatura para ${request.file.name}: $e');
    } finally {
      _loadingThumbnailPaths.remove(request.file.path);
      if (_activeThumbnailLoads > 0) {
        _activeThumbnailLoads--;
      }
      _pumpThumbnailQueue();
    }
  }

  String formatModifiedAt(RemoteFile file) {
    return formatTimestamp(file.modifiedAt);
  }

  String formatLocalModifiedAt(LocalFile file) {
    return formatTimestamp(file.lastModified);
  }

  String formatTimestamp(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _resetVisibleRemoteFilesPagination() {
    _visibleRemoteFileCount = _visibleRemoteFileBatchSize;
  }

  void _resetVisibleLocalFilesPagination() {
    _visibleLocalFileCount = _visibleRemoteFileBatchSize;
  }

  void _invalidateVisibleRemoteFilesCache() {
    _visibleRemoteFilesCache = null;
  }

  void _invalidateVisibleLocalFilesCache() {
    _visibleLocalFilesCache = null;
  }

  String _normalizeRemotePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '/') return '/';
    final normalized = p.posix.normalize(
      trimmed.startsWith('/') ? trimmed : '/$trimmed',
    );
    return normalized == '.' || normalized.isEmpty ? '/' : normalized;
  }

  String _normalizeLocalPath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return _defaultLocalPath();
    return p.normalize(trimmed);
  }

  Future<void> _refreshRemoteFiles(String path) async {
    try {
      final freshFiles = await getRemoteFiles.execute(path, profile);
      if (currentRemotePath != path) return;
      remoteFiles = freshFiles;
      _remoteCache[path] = List<RemoteFile>.of(freshFiles);
      _invalidateVisibleRemoteFilesCache();
      unawaited(_trackFileVersions());
      error = null;
      _notifyIfActive();
    } catch (e) {
      if (currentRemotePath != path) return;
      remoteFiles = [];
      error = 'Error al listar archivos: $e';
      debugPrint('HOTFTP: loadRemoteFiles failed for $path -> $e');
      _notifyIfActive();
    }
  }

  Future<void> _refreshLocalFiles(String path) async {
    try {
      var freshFiles = await getLocalFileDetails.execute(path);
      if (currentLocalPath != path) return;

      final candidates = freshFiles.where((file) {
        if (file.isDirectory) return false;
        return file.size == 0;
      }).toList(growable: false);

      var repairedAny = false;
      for (final file in candidates) {
        final repaired = await repairLocalFile(
          file,
          refreshAfterRepair: false,
        );
        repairedAny = repairedAny || repaired;
      }

      if (repairedAny) {
        freshFiles = await getLocalFileDetails.execute(path);
        if (currentLocalPath != path) return;
      }

      localFiles = freshFiles;
      _localCache[path] = List<LocalFile>.of(freshFiles);
      _invalidateVisibleLocalFilesCache();
      error = null;
      _notifyIfActive();
    } catch (e) {
      if (currentLocalPath != path) return;
      localFiles = [];
      error = 'Error al listar archivos locales: $e';
      debugPrint('HOTFTP: loadLocalFiles failed for $path -> $e');
      _notifyIfActive();
    }
  }

  Future<void> _trackFileVersions() async {
    if (profile.id == null ||
        profile.transportType == FtpTransportType.direct) {
      return;
    }
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

  void _notifyIfActive() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _ThumbnailRequest {
  final RemoteFile file;
  final String remotePath;

  const _ThumbnailRequest({required this.file, required this.remotePath});
}
