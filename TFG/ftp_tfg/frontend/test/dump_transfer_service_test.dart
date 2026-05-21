import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

import 'package:ftp_tfg/core/services/dump_transfer_service.dart';
import 'package:ftp_tfg/domain/entities/dump_schedule.dart';
import 'package:ftp_tfg/domain/entities/ftp_profile.dart';
import 'package:ftp_tfg/domain/entities/local_file.dart';
import 'package:ftp_tfg/domain/entities/remote_file.dart';
import 'package:ftp_tfg/domain/entities/sync_conflict.dart';
import 'package:ftp_tfg/domain/entities/sync_record.dart';
import 'package:ftp_tfg/domain/repositories/ftp_repository.dart';

void main() {
  test('push syncs nested folders recursively and creates remote directories', () async {
    final tempDir = await Directory.systemTemp.createTemp('hotftp-sync-push-');
    addTearDown(() => tempDir.delete(recursive: true));

    await Directory(p.join(tempDir.path, 'docs', 'nested')).create(recursive: true);
    final localFile = File(p.join(tempDir.path, 'docs', 'nested', 'note.txt'));
    await localFile.writeAsString('hello from local');
    localFile.setLastModifiedSync(DateTime(2026, 1, 1, 12));

    final repo = _InMemoryTreeRepository();
    final service = DumpTransferService(repo);
    final profile = _profile();

    final result = await service.execute(
      profile: profile,
      localPath: tempDir.path,
      remotePath: '/backup',
      transferMode: DumpTransferMode.oneWay,
      sourceSide: DumpSourceSide.local,
      deleteSourceAfterCopy: false,
    );

    expect(result.transferred, 1);
    expect(repo.createdDirectories, contains('/backup/docs'));
    expect(repo.createdDirectories, contains('/backup/docs/nested'));
    expect(repo.remoteFiles, contains('/backup/docs/nested/note.txt'));
  });

  test('pull syncs nested folders recursively to local disk', () async {
    final tempDir = await Directory.systemTemp.createTemp('hotftp-sync-pull-');
    addTearDown(() => tempDir.delete(recursive: true));

    final repo = _InMemoryTreeRepository();
    repo.seedRemoteDirectory('/remote');
    repo.seedRemoteDirectory('/remote/assets');
    repo.seedRemoteDirectory('/remote/assets/images');
    repo.seedRemoteFile(
      '/remote/assets/images/logo.png',
      bytes: [1, 2, 3, 4],
      modifiedAt: DateTime(2026, 1, 2, 8),
    );

    final service = DumpTransferService(repo);
    final profile = _profile();

    final result = await service.execute(
      profile: profile,
      localPath: tempDir.path,
      remotePath: '/remote',
      transferMode: DumpTransferMode.oneWay,
      sourceSide: DumpSourceSide.remote,
      deleteSourceAfterCopy: false,
    );

    expect(result.transferred, 1);
    expect(File(p.join(tempDir.path, 'assets', 'images', 'logo.png')).existsSync(), isTrue);
    expect(repo.downloadedFiles, contains('/remote/assets/images/logo.png'));
  });

  test('bidirectional uses the newer side by relative path', () async {
    final tempDir = await Directory.systemTemp.createTemp('hotftp-sync-bidir-');
    addTearDown(() => tempDir.delete(recursive: true));

    await Directory(p.join(tempDir.path, 'local-only')).create(recursive: true);
    final localNewer = File(p.join(tempDir.path, 'local-only', 'fresh.txt'));
    await localNewer.writeAsString('local newer');
    localNewer.setLastModifiedSync(DateTime(2026, 1, 3, 10));

    final remoteOlderPath = '/sync/shared/older.txt';
    final remoteNewerPath = '/sync/remote-only/cloud.txt';

    final repo = _InMemoryTreeRepository();
    repo.seedRemoteDirectory('/sync');
    repo.seedRemoteDirectory('/sync/shared');
    repo.seedRemoteDirectory('/sync/remote-only');
    repo.seedRemoteFile(
      remoteOlderPath,
      bytes: [9, 9],
      modifiedAt: DateTime(2026, 1, 1, 10),
    );
    repo.seedRemoteFile(
      remoteNewerPath,
      bytes: [8, 8, 8],
      modifiedAt: DateTime(2026, 1, 4, 10),
    );

    final remoteSharedLocal = File(p.join(tempDir.path, 'shared', 'older.txt'));
    await Directory(remoteSharedLocal.parent.path).create(recursive: true);
    await remoteSharedLocal.writeAsString('local older copy');
    remoteSharedLocal.setLastModifiedSync(DateTime(2025, 12, 31, 9));

    final service = DumpTransferService(repo);
    final profile = _profile();

    final result = await service.execute(
      profile: profile,
      localPath: tempDir.path,
      remotePath: '/sync',
      transferMode: DumpTransferMode.syncBoth,
      sourceSide: DumpSourceSide.local,
      deleteSourceAfterCopy: false,
    );

    expect(result.transferred, 3);
    expect(repo.uploadedFiles, contains('/sync/local-only/fresh.txt'));
    expect(repo.downloadedFiles, contains('/sync/remote-only/cloud.txt'));
    expect(File(p.join(tempDir.path, 'remote-only', 'cloud.txt')).existsSync(), isTrue);
  });

  test('bidirectional mirrors empty directories to the missing side', () async {
    final tempDir = await Directory.systemTemp.createTemp('hotftp-sync-bidir-dirs-');
    addTearDown(() => tempDir.delete(recursive: true));

    await Directory(p.join(tempDir.path, 'local-empty')).create(recursive: true);

    final repo = _InMemoryTreeRepository();
    repo.seedRemoteDirectory('/sync');
    repo.seedRemoteDirectory('/sync/remote-empty');

    final service = DumpTransferService(repo);
    final profile = _profile();

    final result = await service.execute(
      profile: profile,
      localPath: tempDir.path,
      remotePath: '/sync',
      transferMode: DumpTransferMode.syncBoth,
      sourceSide: DumpSourceSide.local,
      deleteSourceAfterCopy: false,
    );

    expect(result.directoriesCreated, 2);
    expect(repo.createdDirectories, contains('/sync/local-empty'));
    expect(Directory(p.join(tempDir.path, 'remote-empty')).existsSync(), isTrue);
  });
}

FtpProfile _profile() {
  return FtpProfile(
    id: 1,
    ownerId: 'owner-1',
    name: 'Perfil',
    host: 'localhost',
    port: 21,
    username: 'user',
    password: 'pass',
  );
}

class _InMemoryTreeRepository implements FtpRepository {
  final Map<String, _RemoteNode> _files = {};
  final Set<String> _directories = {'/'};
  final List<String> createdDirectories = [];
  final List<String> uploadedFiles = [];
  final List<String> downloadedFiles = [];

  Set<String> get remoteFiles => _files.keys.toSet();

  void seedRemoteDirectory(String path) {
    _directories.add(_normalizeRemote(path));
  }

  void seedRemoteFile(
    String path, {
    required List<int> bytes,
    required DateTime modifiedAt,
  }) {
    final normalized = _normalizeRemote(path);
    _files[normalized] = _RemoteNode(bytes: bytes, modifiedAt: modifiedAt);
    _directories.add(_parentOf(normalized));
  }

  @override
  Future<List<RemoteFile>> getRemoteFiles(String path, FtpProfile profile) async {
    final normalized = _normalizeRemote(path);
    final prefix = normalized == '/' ? '/' : '$normalized/';
    final seen = <String>{};
    final items = <RemoteFile>[];

    for (final dir in _directories) {
      if (dir == normalized || !dir.startsWith(prefix)) continue;
      final relative = dir.substring(prefix.length);
      if (relative.isEmpty || relative.contains('/')) {
        if (relative.contains('/')) {
          final child = relative.split('/').first;
          final childPath = normalized == '/' ? '/$child' : '$normalized/$child';
          if (seen.add(childPath)) {
            items.add(RemoteFile(
              name: child,
              path: childPath,
              size: 0,
              isDirectory: true,
              modifiedAt: null,
            ));
          }
        }
        continue;
      }
      if (seen.add(dir)) {
        items.add(RemoteFile(
          name: relative,
          path: dir,
          size: 0,
          isDirectory: true,
          modifiedAt: null,
        ));
      }
    }

    for (final entry in _files.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      final relative = entry.key.substring(prefix.length);
      if (relative.isEmpty || relative.contains('/')) continue;
      if (seen.add(entry.key)) {
        items.add(RemoteFile(
          name: relative,
          path: entry.key,
          size: entry.value.bytes.length,
          isDirectory: false,
          modifiedAt: entry.value.modifiedAt,
        ));
      }
    }

    return items;
  }

  @override
  Future<List<String>> getLocalFiles(String path) async => throw UnimplementedError();

  @override
  Future<List<LocalFile>> getLocalFileDetails(String path) async => throw UnimplementedError();

  @override
  Future<void> uploadFile(String localPath, String remotePath, FtpProfile profile) async {
    final source = File(localPath);
    final bytes = await source.readAsBytes();
    final normalizedRemotePath = _normalizeRemote(remotePath);
    final fileName = p.basename(localPath);
    final fullPath = normalizedRemotePath == '/' ? '/$fileName' : '$normalizedRemotePath/$fileName';
    _files[fullPath] = _RemoteNode(bytes: bytes, modifiedAt: await source.lastModified());
    _directories.add(_parentOf(fullPath));
    uploadedFiles.add(fullPath);
  }

  @override
  Future<void> createRemoteDirectory(String remotePath, FtpProfile profile) async {
    final normalized = _normalizeRemote(remotePath);
    _directories.add(normalized);
    createdDirectories.add(normalized);
  }

  @override
  Future<void> downloadFile(RemoteFile file, String localPath, FtpProfile profile, {void Function(double progress)? onProgress}) async {
    final node = _files[_normalizeRemote(file.path)];
    if (node == null) {
      throw StateError('Remote file not found: ${file.path}');
    }
    final output = File(p.join(localPath, file.name));
    await output.parent.create(recursive: true);
    await output.writeAsBytes(node.bytes);
    if (onProgress != null) onProgress(1.0);
    downloadedFiles.add(_normalizeRemote(file.path));
  }


  @override
  Future<void> deleteRemoteFile(RemoteFile file, FtpProfile profile) async {
    _files.remove(_normalizeRemote(file.path));
  }

  @override
  Future<void> deleteLocalFile(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  @override
  Future<String> downloadThumbnail(RemoteFile file, String remotePath, FtpProfile profile) async {
    throw UnimplementedError();
  }

  @override
  Future<List<SyncConflict>> detectConflicts(String localPath, String remotePath, FtpProfile profile) async {
    return [];
  }

  @override
  Future<bool> testConnection(FtpProfile profile) async => true;

  @override
  Future<List<SyncRecord>> getSyncHistory(String ownerId) async => [];

  @override
  Future<void> saveSyncRecord(SyncRecord record, FtpProfile profile) async {}

  @override
  Future<List<FtpProfile>> getProfiles(String ownerId) async => [];

  @override
  Future<int> saveProfile(FtpProfile profile, String ownerId) async => 1;

  @override
  Future<void> deleteProfile(FtpProfile profile, String ownerId) async {}

  @override
  Future<DumpSchedule?> getDumpScheduleForProfile(String ownerId, FtpProfile profile) async => null;

  @override
  Future<int> saveDumpSchedule(DumpSchedule schedule, FtpProfile profile) async => 1;

  String _normalizeRemote(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty || trimmed == '/') return '/';
    return p.posix.normalize(trimmed.startsWith('/') ? trimmed : '/$trimmed');
  }

  String _parentOf(String path) {
    final parent = p.posix.dirname(path);
    return parent == '.' ? '/' : parent;
  }
}

class _RemoteNode {
  final List<int> bytes;
  final DateTime modifiedAt;

  _RemoteNode({required this.bytes, required this.modifiedAt});
}






