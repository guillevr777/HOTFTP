import '../../domain/entities/dump_schedule.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/local_file.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/repositories/ftp_repository.dart';

class DumpTransferResult {
  final int transferred;
  final int skipped;
  final int deleted;

  const DumpTransferResult({
    required this.transferred,
    required this.skipped,
    required this.deleted,
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
  }) async {
    final localFiles = await repository.getLocalFileDetails(localPath);
    final remoteFiles = await repository.getRemoteFiles(remotePath, profile);
    final remoteFilesByName = {
      for (final file in remoteFiles.where((file) => !file.isDirectory))
        file.name: file,
    };
    final localFilesByName = {
      for (final file in localFiles.where((file) => !file.isDirectory))
        file.name: file,
    };

    var transferred = 0;
    var skipped = 0;
    var deleted = 0;

    if (transferMode == DumpTransferMode.syncBoth) {
      final allNames = <String>{
        ...localFilesByName.keys,
        ...remoteFilesByName.keys,
      };
      for (final name in allNames) {
        final local = localFilesByName[name];
        final remote = remoteFilesByName[name];
        switch (_resolveBidirectionalDirection(local, remote)) {
          case _TransferDirection.upload:
            await repository.uploadFile(local!.path, remotePath, profile);
            transferred++;
            break;
          case _TransferDirection.download:
            await repository.downloadFile(remote!, localPath, profile);
            transferred++;
            break;
          case _TransferDirection.skip:
            skipped++;
            break;
        }
      }
      return DumpTransferResult(
        transferred: transferred,
        skipped: skipped,
        deleted: deleted,
      );
    }

    if (sourceSide == DumpSourceSide.local) {
      for (final local in localFiles.where((file) => !file.isDirectory)) {
        final remote = remoteFilesByName[local.name];
        final shouldCopy = remote == null ||
            _shouldTransfer(
              sourceDate: local.lastModified,
              sourceSize: local.size,
              targetDate: remote.modifiedAt,
              targetSize: remote.size,
            );
        if (!shouldCopy) {
          skipped++;
          continue;
        }
        await repository.uploadFile(local.path, remotePath, profile);
        transferred++;
        if (deleteSourceAfterCopy) {
          await repository.deleteLocalFile(local.path);
          deleted++;
        }
      }
      return DumpTransferResult(
        transferred: transferred,
        skipped: skipped,
        deleted: deleted,
      );
    }

    for (final remote in remoteFiles.where((file) => !file.isDirectory)) {
      final local = localFilesByName[remote.name];
      final shouldCopy = local == null ||
          _shouldTransfer(
            sourceDate: remote.modifiedAt,
            sourceSize: remote.size,
            targetDate: local.lastModified,
            targetSize: local.size,
          );
      if (!shouldCopy) {
        skipped++;
        continue;
      }
      await repository.downloadFile(remote, localPath, profile);
      transferred++;
      if (deleteSourceAfterCopy) {
        await repository.deleteRemoteFile(remote, profile);
        deleted++;
      }
    }

    return DumpTransferResult(
      transferred: transferred,
      skipped: skipped,
      deleted: deleted,
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
    LocalFile? local,
    RemoteFile? remote,
  ) {
    if (local == null && remote == null) return _TransferDirection.skip;
    if (local != null && remote == null) return _TransferDirection.upload;
    if (local == null && remote != null) return _TransferDirection.download;

    final localDate = local!.lastModified;
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
}

enum _TransferDirection { upload, download, skip }



