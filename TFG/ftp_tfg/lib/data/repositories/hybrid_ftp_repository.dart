import '../../domain/entities/dump_schedule.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/local_file.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/entities/sync_conflict.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/repositories/ftp_repository.dart';

class HybridFtpRepositoryImpl implements FtpRepository {
  final FtpRepository localRepository;
  final FtpRepository remoteRepository;

  HybridFtpRepositoryImpl({
    required this.localRepository,
    required this.remoteRepository,
  });

  bool _isLocal(FtpProfile profile) =>
      profile.transportType == FtpTransportType.local;

  FtpRepository _repositoryFor(FtpProfile profile) =>
      _isLocal(profile) ? localRepository : remoteRepository;

  @override
  Future<List<RemoteFile>> getRemoteFiles(
    String path,
    FtpProfile profile,
  ) =>
      _repositoryFor(profile).getRemoteFiles(path, profile);

  @override
  Future<List<String>> getLocalFiles(String path) =>
      localRepository.getLocalFiles(path);

  @override
  Future<List<LocalFile>> getLocalFileDetails(String path) =>
      localRepository.getLocalFileDetails(path);

  @override
  Future<void> uploadFile(
    String localPath,
    String remotePath,
    FtpProfile profile,
  ) =>
      _repositoryFor(profile).uploadFile(localPath, remotePath, profile);

  @override
  Future<void> downloadFile(
    RemoteFile file,
    String localPath,
    FtpProfile profile,
  ) =>
      _repositoryFor(profile).downloadFile(file, localPath, profile);

  @override
  Future<void> deleteRemoteFile(RemoteFile file, FtpProfile profile) =>
      _repositoryFor(profile).deleteRemoteFile(file, profile);

  @override
  Future<void> deleteLocalFile(String path) => localRepository.deleteLocalFile(path);

  @override
  Future<String> downloadThumbnail(
    RemoteFile file,
    String remotePath,
    FtpProfile profile,
  ) =>
      _repositoryFor(profile).downloadThumbnail(file, remotePath, profile);

  @override
  Future<List<SyncConflict>> detectConflicts(
    String localPath,
    String remotePath,
    FtpProfile profile,
  ) =>
      _repositoryFor(profile).detectConflicts(localPath, remotePath, profile);

  @override
  Future<List<FtpProfile>> getProfiles(String ownerId) async {
    final local = await localRepository.getProfiles(ownerId);
    List<FtpProfile> remote = [];
    try {
      remote = await remoteRepository.getProfiles(ownerId);
    } catch (_) {}

    final merged = [...local, ...remote];
    merged.sort((a, b) {
      final nameCompare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (nameCompare != 0) return nameCompare;
      return a.transportType.index.compareTo(b.transportType.index);
    });
    return merged;
  }

  @override
  Future<int> saveProfile(FtpProfile profile, String ownerId) =>
      _repositoryFor(profile).saveProfile(profile, ownerId);

  @override
  Future<void> deleteProfile(FtpProfile profile, String ownerId) =>
      _repositoryFor(profile).deleteProfile(profile, ownerId);

  @override
  Future<bool> testConnection(FtpProfile profile) =>
      _repositoryFor(profile).testConnection(profile);

  @override
  Future<List<SyncRecord>> getSyncHistory(String ownerId) async {
    final local = await localRepository.getSyncHistory(ownerId);
    List<SyncRecord> remote = [];
    try {
      remote = await remoteRepository.getSyncHistory(ownerId);
    } catch (_) {}

    final merged = [...local, ...remote];
    merged.sort((a, b) => b.date.compareTo(a.date));
    return merged;
  }

  @override
  Future<void> saveSyncRecord(SyncRecord record, FtpProfile profile) =>
      _repositoryFor(profile).saveSyncRecord(record, profile);

  @override
  Future<DumpSchedule?> getDumpScheduleForProfile(
    String ownerId,
    FtpProfile profile,
  ) =>
      _repositoryFor(profile).getDumpScheduleForProfile(ownerId, profile);

  @override
  Future<int> saveDumpSchedule(
    DumpSchedule schedule,
    FtpProfile profile,
  ) =>
      _repositoryFor(profile).saveDumpSchedule(schedule, profile);
}
