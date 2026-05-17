import 'package:flutter_test/flutter_test.dart';
import 'package:ftp_tfg/data/repositories/hybrid_ftp_repository.dart';
import 'package:ftp_tfg/domain/entities/dump_schedule.dart';
import 'package:ftp_tfg/domain/entities/ftp_profile.dart';
import 'package:ftp_tfg/domain/entities/local_file.dart';
import 'package:ftp_tfg/domain/entities/remote_file.dart';
import 'package:ftp_tfg/domain/entities/sync_conflict.dart';
import 'package:ftp_tfg/domain/entities/sync_record.dart';
import 'package:ftp_tfg/domain/repositories/ftp_repository.dart';

void main() {
  test('migrates local profiles to the remote repository', () async {
    final local = _StubFtpRepository(
      profiles: [
        FtpProfile(
          id: 1,
          ownerId: 'owner-1',
          name: 'Servidor local',
          host: 'ftp.example.com',
          port: 21,
          username: 'user',
          password: 'pass',
        ),
      ],
    );
    final remote = _StubFtpRepository();
    final repo = HybridFtpRepositoryImpl(
      localRepository: local,
      remoteRepository: remote,
    );

    final profiles = await repo.getProfiles('owner-1');

    expect(remote.saveCalls, 1);
    expect(profiles, hasLength(1));
    expect(remote.profiles, hasLength(1));
    expect(remote.profiles.first.ownerId, 'owner-1');
    expect(remote.profiles.first.id, 101);
  });

  test('saves and deletes profiles through the remote repository', () async {
    final local = _StubFtpRepository();
    final remote = _StubFtpRepository();
    final repo = HybridFtpRepositoryImpl(
      localRepository: local,
      remoteRepository: remote,
    );
    final profile = FtpProfile(
      id: 9,
      ownerId: 'owner-1',
      name: 'Perfil nube',
      host: 'ftp.example.com',
      port: 21,
      username: 'user',
      password: 'pass',
    );

    await repo.saveProfile(profile, 'owner-1');
    await repo.deleteProfile(profile, 'owner-1');

    expect(remote.saveCalls, 1);
    expect(remote.deleteCalls, 1);
    expect(local.saveCalls, 0);
    expect(local.deleteCalls, 0);
  });
}

class _StubFtpRepository implements FtpRepository {
  _StubFtpRepository({List<FtpProfile>? profiles}) : profiles = profiles ?? [];

  final List<FtpProfile> profiles;
  int saveCalls = 0;
  int deleteCalls = 0;

  @override
  Future<List<FtpProfile>> getProfiles(String ownerId) async {
    return profiles.where((profile) => profile.ownerId == ownerId).toList();
  }

  @override
  Future<int> saveProfile(FtpProfile profile, String ownerId) async {
    saveCalls++;
    final saved = profile.copyWith(id: 100 + saveCalls, ownerId: ownerId);
    profiles.add(saved);
    return saved.id!;
  }

  @override
  Future<void> deleteProfile(FtpProfile profile, String ownerId) async {
    deleteCalls++;
    profiles.removeWhere(
      (item) => item.id == profile.id && item.ownerId == ownerId,
    );
  }

  @override
  Future<List<RemoteFile>> getRemoteFiles(
    String path,
    FtpProfile profile,
  ) async => throw UnimplementedError();

  @override
  Future<List<String>> getLocalFiles(String path) async =>
      throw UnimplementedError();

  @override
  Future<List<LocalFile>> getLocalFileDetails(String path) async =>
      throw UnimplementedError();

  @override
  Future<void> uploadFile(
    String localPath,
    String remotePath,
    FtpProfile profile,
  ) async => throw UnimplementedError();

  @override
  Future<void> downloadFile(
    RemoteFile file,
    String localPath,
    FtpProfile profile,
  ) async => throw UnimplementedError();

  @override
  Future<void> deleteRemoteFile(RemoteFile file, FtpProfile profile) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteLocalFile(String path) async => throw UnimplementedError();

  @override
  Future<String> downloadThumbnail(
    RemoteFile file,
    String remotePath,
    FtpProfile profile,
  ) async => throw UnimplementedError();

  @override
  Future<List<SyncConflict>> detectConflicts(
    String localPath,
    String remotePath,
    FtpProfile profile,
  ) async => throw UnimplementedError();

  @override
  Future<bool> testConnection(FtpProfile profile) async =>
      throw UnimplementedError();

  @override
  Future<List<SyncRecord>> getSyncHistory(String ownerId) async =>
      throw UnimplementedError();

  @override
  Future<void> saveSyncRecord(SyncRecord record, FtpProfile profile) async =>
      throw UnimplementedError();

  @override
  Future<DumpSchedule?> getDumpScheduleForProfile(
    String ownerId,
    FtpProfile profile,
  ) async => throw UnimplementedError();

  @override
  Future<int> saveDumpSchedule(
    DumpSchedule schedule,
    FtpProfile profile,
  ) async => throw UnimplementedError();
}
