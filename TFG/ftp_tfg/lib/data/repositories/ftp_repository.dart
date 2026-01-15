import '../../domain/entities/remote_file.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../datasources/fake_datasource.dart';
import '../mappers/remote_file_mapper.dart';

class FtpRepositoryImpl implements FtpRepository {
  final FakeFtpDatasource datasource;

  FtpRepositoryImpl(this.datasource);

  @override
  Future<List<RemoteFile>> getRemoteFiles(String path) async {
    final data = await datasource.listFiles(path);
    return data.map(RemoteFileMapper.fromMap).toList();
  }
}
