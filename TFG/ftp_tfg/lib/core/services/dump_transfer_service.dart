import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

import '../../domain/entities/dump_schedule.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/repositories/ftp_repository.dart';

typedef DumpTransferProgressCallback = void Function(
  DumpTransferProgress progress,
);

class DumpTransferProgress {
  final int processed;
  final int total;
  final int transferred;
  final int skipped;
  final int deleted;
  final int directoriesCreated;
  final String stage;
  final String? currentPath;
  final bool currentIsDirectory;

  const DumpTransferProgress({
    required this.processed,
    required this.total,
    required this.transferred,
    required this.skipped,
    required this.deleted,
    required this.directoriesCreated,
    required this.stage,
    this.currentPath,
    this.currentIsDirectory = false,
  });
}

class DumpTransferResult {
  final int transferred;
  final int skipped;
  final int deleted;
  final int directoriesCreated;

  const DumpTransferResult({
    required this.transferred,
    required this.skipped,
    required this.deleted,
    this.directoriesCreated = 0,
  });
}

class DumpTransferService {
  final FtpRepository repository;

  DumpTransferService(this.repository);

  Future<DumpTransferResult> execute({
    required FtpProfile profile,
    required String localPath,
    required String remotePath,
    required DumpTransferMode transferMode,
    required DumpSourceSide sourceSide,
    required bool deleteSourceAfterCopy,
    DumpTransferProgressCallback? onProgress,
  }) async {
    final normalizedLocalPath = _normalizeLocalPath(localPath);
    final normalizedRemotePath = _normalizeRemotePath(remotePath);

    final localTree = await _collectLocalTree(normalizedLocalPath);
    final remoteTree = await _collectRemoteTree(normalizedRemotePath, profile);
    final totalOperations = _countPlannedOperations(
      transferMode: transferMode,
      sourceSide: sourceSide,
      localTree: localTree,
      remoteTree: remoteTree,
    );

    _reportProgress(
      onProgress,
      processed: 0,
      total: totalOperations,
      transferred: 0,
      skipped: 0,
      deleted: 0,
      directoriesCreated: 0,
      stage: 'preparing',
      currentPath: normalizedRemotePath,
      currentIsDirectory: true,
    );

    if (transferMode == DumpTransferMode.syncBoth) {
      return _syncBidirectional(
        profile: profile,
        localRoot: normalizedLocalPath,
        remoteRoot: normalizedRemotePath,
        localTree: localTree,
        remoteTree: remoteTree,
        totalOperations: totalOperations,
        onProgress: onProgress,
      );
    }

    if (sourceSide == DumpSourceSide.local) {
      return _syncFromLocal(
        profile: profile,
        localRoot: normalizedLocalPath,
        remoteRoot: normalizedRemotePath,
        localTree: localTree,
        remoteTree: remoteTree,
        deleteSourceAfterCopy: deleteSourceAfterCopy,
        totalOperations: totalOperations,
        onProgress: onProgress,
      );
    }

    return _syncFromRemote(
      profile: profile,
      localRoot: normalizedLocalPath,
      remoteRoot: normalizedRemotePath,
      localTree: localTree,
      remoteTree: remoteTree,
      deleteSourceAfterCopy: deleteSourceAfterCopy,
      totalOperations: totalOperations,
      onProgress: onProgress,
    );
  }

  Future<DumpTransferResult> _syncBidirectional({
    required FtpProfile profile,
    required String localRoot,
    required String remoteRoot,
    required _LocalTree localTree,
    required _RemoteTree remoteTree,
    required int totalOperations,
    DumpTransferProgressCallback? onProgress,
  }) async {
    var transferred = 0;
    var skipped = 0;
    var deleted = 0;
    var directoriesCreated = 0;
    var processed = 0;

    final localDirs = <String>{...localTree.directories};
    final remoteDirs = <String>{...remoteTree.directories};
    for (final dir in _sortedRelativePaths({...localDirs, ...remoteDirs})) {
      final localDirPath = p.join(localRoot, dir);
      final remoteDirPath = p.posix.join(remoteRoot, dir);
      if (localDirs.contains(dir) && !remoteDirs.contains(dir)) {
        if (await _ensureLocalDirectory(localDirPath)) {
          directoriesCreated++;
        }
      }
      if (remoteDirs.contains(dir) && !localDirs.contains(dir)) {
        if (await _ensureRemoteDirectory(
          remoteDirPath,
          profile,
          remoteDirs,
        )) {
          directoriesCreated++;
        }
      }
      processed++;
      _reportProgress(
        onProgress,
        processed: processed,
        total: totalOperations,
        transferred: transferred,
        skipped: skipped,
        deleted: deleted,
        directoriesCreated: directoriesCreated,
        stage: 'syncing_directory',
        currentPath: remoteDirs.contains(dir) ? remoteDirPath : localDirPath,
        currentIsDirectory: true,
      );
    }

    final allFiles = <String>{
      ...localTree.files.keys,
      ...remoteTree.files.keys,
    };
    for (final relativePath in _sortedRelativePaths(allFiles)) {
      final local = localTree.files[relativePath];
      final remote = remoteTree.files[relativePath];
      final displayPath = local?.path ?? remote?.file.path ?? relativePath;
      switch (_resolveBidirectionalDirection(local, remote)) {
        case _TransferDirection.upload:
          if (local == null) {
            skipped++;
            processed++;
            _reportProgress(
              onProgress,
              processed: processed,
              total: totalOperations,
              transferred: transferred,
              skipped: skipped,
              deleted: deleted,
              directoriesCreated: directoriesCreated,
              stage: 'skipping',
              currentPath: displayPath,
            );
            break;
          }
          final remoteParent = _remoteParentPath(remoteRoot, relativePath);
          await _ensureRemoteDirectory(
            remoteParent,
            profile,
            remoteDirs,
          );
          await repository.uploadFile(local.path, remoteParent, profile);
          transferred++;
          processed++;
          _reportProgress(
            onProgress,
            processed: processed,
            total: totalOperations,
            transferred: transferred,
            skipped: skipped,
            deleted: deleted,
            directoriesCreated: directoriesCreated,
            stage: 'uploading',
            currentPath: local.path,
          );
          break;
        case _TransferDirection.download:
          if (remote == null) {
            skipped++;
            processed++;
            _reportProgress(
              onProgress,
              processed: processed,
              total: totalOperations,
              transferred: transferred,
              skipped: skipped,
              deleted: deleted,
              directoriesCreated: directoriesCreated,
              stage: 'skipping',
              currentPath: displayPath,
            );
            break;
          }
          final localParent = _localParentPath(localRoot, relativePath);
          await _ensureLocalDirectory(localParent);
          await repository.downloadFile(remote.file, localParent, profile);
          transferred++;
          processed++;
          _reportProgress(
            onProgress,
            processed: processed,
            total: totalOperations,
            transferred: transferred,
            skipped: skipped,
            deleted: deleted,
            directoriesCreated: directoriesCreated,
            stage: 'downloading',
            currentPath: remote.file.path,
          );
          break;
        case _TransferDirection.skip:
          skipped++;
          processed++;
          _reportProgress(
            onProgress,
            processed: processed,
            total: totalOperations,
            transferred: transferred,
            skipped: skipped,
            deleted: deleted,
            directoriesCreated: directoriesCreated,
            stage: 'skipping',
            currentPath: displayPath,
          );
          break;
      }
    }

    return DumpTransferResult(
      transferred: transferred,
      skipped: skipped,
      deleted: deleted,
      directoriesCreated: directoriesCreated,
    );
  }

  Future<DumpTransferResult> _syncFromLocal({
    required FtpProfile profile,
    required String localRoot,
    required String remoteRoot,
    required _LocalTree localTree,
    required _RemoteTree remoteTree,
    required bool deleteSourceAfterCopy,
    required int totalOperations,
    DumpTransferProgressCallback? onProgress,
  }) async {
    var transferred = 0;
    var skipped = 0;
    var deleted = 0;
    var directoriesCreated = 0;
    var processed = 0;
    final remoteDirs = <String>{...remoteTree.directories};

    for (final dir in _sortedRelativePaths(localTree.directories)) {
      final remoteDirPath = p.posix.join(remoteRoot, dir);
      if (await _ensureRemoteDirectory(
        remoteDirPath,
        profile,
        remoteDirs,
      )) {
        directoriesCreated++;
      }
      processed++;
      _reportProgress(
        onProgress,
        processed: processed,
        total: totalOperations,
        transferred: transferred,
        skipped: skipped,
        deleted: deleted,
        directoriesCreated: directoriesCreated,
        stage: 'creating_remote_directory',
        currentPath: remoteDirPath,
        currentIsDirectory: true,
      );
    }

    for (final relativePath in _sortedRelativePaths(localTree.files.keys)) {
      final local = localTree.files[relativePath]!;
      final remote = remoteTree.files[relativePath];
      final shouldCopy = remote == null ||
          _shouldTransfer(
            sourceDate: local.modifiedAt,
            sourceSize: local.size,
            targetDate: remote.modifiedAt,
            targetSize: remote.size,
          );
      if (!shouldCopy) {
        skipped++;
        processed++;
        _reportProgress(
          onProgress,
          processed: processed,
          total: totalOperations,
          transferred: transferred,
          skipped: skipped,
          deleted: deleted,
          directoriesCreated: directoriesCreated,
          stage: 'skipping',
          currentPath: local.path,
        );
        continue;
      }
      final remoteParent = _remoteParentPath(remoteRoot, relativePath);
      await _ensureRemoteDirectory(remoteParent, profile, remoteDirs);
      await repository.uploadFile(local.path, remoteParent, profile);
      transferred++;
      processed++;
      _reportProgress(
        onProgress,
        processed: processed,
        total: totalOperations,
        transferred: transferred,
        skipped: skipped,
        deleted: deleted,
        directoriesCreated: directoriesCreated,
        stage: 'uploading',
        currentPath: local.path,
      );
      if (deleteSourceAfterCopy) {
        await repository.deleteLocalFile(local.path);
        deleted++;
      }
    }

    return DumpTransferResult(
      transferred: transferred,
      skipped: skipped,
      deleted: deleted,
      directoriesCreated: directoriesCreated,
    );
  }

  Future<DumpTransferResult> _syncFromRemote({
    required FtpProfile profile,
    required String localRoot,
    required String remoteRoot,
    required _LocalTree localTree,
    required _RemoteTree remoteTree,
    required bool deleteSourceAfterCopy,
    required int totalOperations,
    DumpTransferProgressCallback? onProgress,
  }) async {
    var transferred = 0;
    var skipped = 0;
    var deleted = 0;
    var directoriesCreated = 0;
    var processed = 0;

    if (await _ensureLocalDirectory(localRoot)) {
      directoriesCreated++;
    }

    for (final dir in _sortedRelativePaths(remoteTree.directories)) {
      final localDirPath = _localAbsolutePath(localRoot, dir);
      if (await _ensureLocalDirectory(localDirPath)) {
        directoriesCreated++;
      }
      processed++;
      _reportProgress(
        onProgress,
        processed: processed,
        total: totalOperations,
        transferred: transferred,
        skipped: skipped,
        deleted: deleted,
        directoriesCreated: directoriesCreated,
        stage: 'creating_local_directory',
        currentPath: localDirPath,
        currentIsDirectory: true,
      );
    }

    for (final relativePath in _sortedRelativePaths(remoteTree.files.keys)) {
      final remote = remoteTree.files[relativePath]!;
      final local = localTree.files[relativePath];
      final shouldCopy = local == null ||
          _shouldTransfer(
            sourceDate: remote.modifiedAt,
            sourceSize: remote.size,
            targetDate: local.modifiedAt,
            targetSize: local.size,
          );
      if (!shouldCopy) {
        skipped++;
        processed++;
        _reportProgress(
          onProgress,
          processed: processed,
          total: totalOperations,
          transferred: transferred,
          skipped: skipped,
          deleted: deleted,
          directoriesCreated: directoriesCreated,
          stage: 'skipping',
          currentPath: remote.file.path,
        );
        continue;
      }
      final localParent = _localParentPath(localRoot, relativePath);
      await _ensureLocalDirectory(localParent);
      await repository.downloadFile(remote.file, localParent, profile);
      transferred++;
      processed++;
      _reportProgress(
        onProgress,
        processed: processed,
        total: totalOperations,
        transferred: transferred,
        skipped: skipped,
        deleted: deleted,
        directoriesCreated: directoriesCreated,
        stage: 'downloading',
        currentPath: remote.file.path,
      );
      if (deleteSourceAfterCopy) {
        await repository.deleteRemoteFile(remote.file, profile);
        deleted++;
      }
    }

    return DumpTransferResult(
      transferred: transferred,
      skipped: skipped,
      deleted: deleted,
      directoriesCreated: directoriesCreated,
    );
  }

  Future<_LocalTree> _collectLocalTree(String root) async {
    final files = <String, _LocalEntry>{};
    final directories = <String>{};
    final directory = Directory(root);
    if (!directory.existsSync()) {
      return _LocalTree(files: files, directories: directories);
    }

    Future<void> visit(Directory current) async {
      await for (final entity in current.list(recursive: false, followLinks: false)) {
        if (entity is Directory) {
          final relative = _relativeLocalPath(root, entity.path);
          if (relative.isNotEmpty) {
            directories.add(relative);
          }
          await visit(entity);
        } else if (entity is File) {
          final stat = await entity.stat();
          final relative = _relativeLocalPath(root, entity.path);
          files[relative] = _LocalEntry(
            path: entity.path,
            relativePath: relative,
            size: stat.size,
            modifiedAt: stat.modified,
          );
        }
      }
    }

    await visit(directory);
    return _LocalTree(files: files, directories: directories);
  }

  Future<_RemoteTree> _collectRemoteTree(String root, FtpProfile profile) async {
    final files = <String, _RemoteEntry>{};
    final directories = <String>{};

    Future<void> visit(String currentPath) async {
      final entries = await repository.getRemoteFiles(currentPath, profile);
      for (final entry in entries) {
        final relative = _relativeRemotePath(root, entry.path);
        if (entry.isDirectory) {
          if (relative.isNotEmpty) {
            directories.add(relative);
          }
          await visit(entry.path);
        } else {
          files[relative] = _RemoteEntry(file: entry, relativePath: relative);
        }
      }
    }

    try {
      await visit(root);
    } catch (_) {
      if (root != '/') {
        await _ensureRemoteDirectory(root, profile, directories);
      }
    }

    return _RemoteTree(files: files, directories: directories);
  }

  Future<bool> _ensureRemoteDirectory(
    String remotePath,
    FtpProfile profile,
    Set<String> existingDirectories,
  ) async {
    final normalized = _normalizeRemotePath(remotePath);
    if (normalized == '/') return false;

    final segments = p.posix.split(normalized);
    var current = '';
    var created = false;
    for (final segment in segments) {
      current = current.isEmpty ? '/$segment' : '$current/$segment';
      final relative = _relativeRemotePath('/', current);
      if (existingDirectories.contains(relative)) {
        continue;
      }
      await repository.createRemoteDirectory(current, profile);
      existingDirectories.add(relative);
      created = true;
    }
    return created;
  }

  Future<bool> _ensureLocalDirectory(String path) async {
    final directory = Directory(path);
    final existed = directory.existsSync();
    await directory.create(recursive: true);
    return !existed;
  }

  String _remoteParentPath(String remoteRoot, String relativePath) {
    final relativeParent = _relativeParent(relativePath);
    return relativeParent.isEmpty
        ? _normalizeRemotePath(remoteRoot)
        : p.posix.join(_normalizeRemotePath(remoteRoot), relativeParent);
  }

  String _localParentPath(String localRoot, String relativePath) {
    final relativeParent = _relativeParent(relativePath);
    return relativeParent.isEmpty ? _normalizeLocalPath(localRoot) : p.join(_normalizeLocalPath(localRoot), relativeParent);
  }

  String _localAbsolutePath(String root, String relativePath) {
    return relativePath.isEmpty ? _normalizeLocalPath(root) : p.join(_normalizeLocalPath(root), relativePath);
  }

  String _relativeParent(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index < 0) return '';
    return normalized.substring(0, index);
  }

  List<String> _sortedRelativePaths(Iterable<String> paths) {
    final list = paths.where((path) => path.isNotEmpty).toList();
    list.sort((a, b) {
      final depthA = a.split('/').length;
      final depthB = b.split('/').length;
      final depthCompare = depthA.compareTo(depthB);
      if (depthCompare != 0) return depthCompare;
      return a.compareTo(b);
    });
    return list;
  }

  int _countPlannedOperations({
    required DumpTransferMode transferMode,
    required DumpSourceSide sourceSide,
    required _LocalTree localTree,
    required _RemoteTree remoteTree,
  }) {
    if (transferMode == DumpTransferMode.syncBoth) {
      return _unionCount(localTree.directories, remoteTree.directories) +
          _unionCount(localTree.files.keys, remoteTree.files.keys);
    }

    if (sourceSide == DumpSourceSide.local) {
      return localTree.directories.length + localTree.files.length;
    }

    return remoteTree.directories.length + remoteTree.files.length;
  }

  int _unionCount(Iterable<String> first, Iterable<String> second) {
    return <String>{...first, ...second}.length;
  }

  void _reportProgress(
    DumpTransferProgressCallback? onProgress, {
    required int processed,
    required int total,
    required int transferred,
    required int skipped,
    required int deleted,
    required int directoriesCreated,
    required String stage,
    String? currentPath,
    bool currentIsDirectory = false,
  }) {
    if (onProgress == null) return;
    onProgress(
      DumpTransferProgress(
        processed: processed,
        total: total,
        transferred: transferred,
        skipped: skipped,
        deleted: deleted,
        directoriesCreated: directoriesCreated,
        stage: stage,
        currentPath: currentPath,
        currentIsDirectory: currentIsDirectory,
      ),
    );
  }

  bool _shouldTransfer({
    required DateTime? sourceDate,
    required int sourceSize,
    required DateTime? targetDate,
    required int targetSize,
  }) {
    if (sourceSize != targetSize) return true;
    if (sourceDate == null && targetDate == null) return false;
    if (sourceDate != null && targetDate == null) return true;
    if (sourceDate == null && targetDate != null) return false;
    return sourceDate!.isAfter(targetDate!);
  }

  _TransferDirection _resolveBidirectionalDirection(
    _LocalEntry? local,
    _RemoteEntry? remote,
  ) {
    if (local == null && remote == null) return _TransferDirection.skip;
    if (local != null && remote == null) return _TransferDirection.upload;
    if (local == null && remote != null) return _TransferDirection.download;

    final localDate = local!.modifiedAt;
    final remoteDate = remote!.modifiedAt;
    if (localDate != null && remoteDate != null) {
      if (localDate.isAfter(remoteDate)) return _TransferDirection.upload;
      if (remoteDate.isAfter(localDate)) return _TransferDirection.download;
      if (local.size == remote.size) return _TransferDirection.skip;
      return _TransferDirection.upload;
    }
    if (localDate != null && remoteDate == null) return _TransferDirection.upload;
    if (localDate == null && remoteDate != null) return _TransferDirection.download;
    if (local.size == remote.size) return _TransferDirection.skip;
    return _TransferDirection.upload;
  }

  String _normalizeLocalPath(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? Directory.current.path : p.normalize(trimmed);
  }

  String _normalizeRemotePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '/') return '/';
    final normalized = p.posix.normalize(
      trimmed.startsWith('/') ? trimmed : '/$trimmed',
    );
    return normalized == '.' || normalized.isEmpty ? '/' : normalized;
  }

  String _relativeLocalPath(String root, String path) {
    final relative = p.relative(path, from: root);
    if (relative == '.' || relative.isEmpty) return '';
    return p.posix.joinAll(p.split(relative));
  }

  String _relativeRemotePath(String root, String path) {
    final relative = p.posix.relative(path, from: root);
    if (relative == '.' || relative.isEmpty) return '';
    return p.posix.normalize(relative);
  }
}

enum _TransferDirection { upload, download, skip }

class _LocalTree {
  final Map<String, _LocalEntry> files;
  final Set<String> directories;

  const _LocalTree({required this.files, required this.directories});
}

class _RemoteTree {
  final Map<String, _RemoteEntry> files;
  final Set<String> directories;

  const _RemoteTree({required this.files, required this.directories});
}

class _LocalEntry {
  final String path;
  final String relativePath;
  final int size;
  final DateTime? modifiedAt;

  const _LocalEntry({
    required this.path,
    required this.relativePath,
    required this.size,
    required this.modifiedAt,
  });
}

class _RemoteEntry {
  final RemoteFile file;
  final String relativePath;

  const _RemoteEntry({required this.file, required this.relativePath});

  int get size => file.size;
  DateTime? get modifiedAt => file.modifiedAt;
}


