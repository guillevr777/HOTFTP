import 'package:ftp_tfg/data/datasources/ftp_datasource.dart';
import 'package:ftp_tfg/domain/entities/remote_file.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../mappers/remote_file_mapper.dart';

class FtpRepositoryImpl implements FtpRepository {
  final FtpDatasourceImpl datasource;

  FtpRepositoryImpl(this.datasource);

  @override
  Future<bool> connect(FtpProfile profile) {
    return datasource.connect(profile);
  }


  @override
  Future<List<RemoteFile>> getRemoteFiles(String path) async {
    final result = await datasource.listFiles(path);
    return result.map(RemoteFileMapper.fromJson).toList();
  }

  @override
  Future<void> uploadFile(String localPath, String remotePath) {
    // TODO
    throw UnimplementedError();
  }

  @override
  Future<void> downloadFile(String remotePath, String localPath) {
    // TODO
    throw UnimplementedError();
  }
}
