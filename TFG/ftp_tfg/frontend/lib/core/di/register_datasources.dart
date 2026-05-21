import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/datasources/ftp_real_datasource.dart';
import '../../data/datasources/hotftp_api_client.dart';

class AppDataSources {
  final HotftpApiClient apiClient;
  final FirebaseAuthDatasource firebaseAuthDatasource;
  final FtpRealDatasource ftpDatasource;

  AppDataSources({
    required this.apiClient,
    required this.firebaseAuthDatasource,
    required this.ftpDatasource,
  });
}

AppDataSources createDataSources() {
  final apiClient = HotftpApiClient();

  return AppDataSources(
    apiClient: apiClient,
    firebaseAuthDatasource: FirebaseAuthDatasource(),
    ftpDatasource: FtpRealDatasource(),
  );
}
