import 'package:ftp_tfg/data/interfaces/ftp_datasource.dart';

import '../../domain/entities/remote_file.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../mappers/remote_file_mapper.dart';

class FtpRepositoryImpl implements FtpRepository {
  final FtpDatasource datasource;

  FtpRepositoryImpl(this.datasource);

  @override
  Future<List<RemoteFile>> getRemoteFiles(String path) async {
    final data = await datasource.listFiles(path);
    return data.map(RemoteFileMapper.fromMap).toList();
  }
}
