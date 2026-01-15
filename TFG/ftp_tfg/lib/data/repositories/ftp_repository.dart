import 'package:ftp_tfg/data/interfaces/ftp_datasource.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/remote_file.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../mappers/remote_file_mapper.dart';

class FtpRepositoryImpl implements FtpRepository {
  final FtpDatasource datasource;

  FtpRepositoryImpl(this.datasource);

  @override
  Future<bool> connect(FtpProfile profile) {
    return datasource.connect(profile);
  }

  @override
  Future<List<RemoteFile>> getRemoteFiles(String path) async {
    final data = await datasource.listFiles(path);
    return data.map(RemoteFileMapper.fromMap).toList();
  }

  @override
  Future<List<String>> getLocalFiles(String localPath) async {
    return ['file1.txt', 'file2.txt'];
  }

  @override
  Future<void> uploadFile(String localFile, String remotePath) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> downloadFile(RemoteFile remoteFile, String localPath) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> syncBidirectional(String localPath, String remotePath) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
