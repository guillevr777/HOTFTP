import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/datasources/hotftp_api_client.dart';

class AppDataSources {
  final HotftpApiClient apiClient;
  final FirebaseAuthDatasource firebaseAuthDatasource;

  AppDataSources({
    required this.apiClient,
    required this.firebaseAuthDatasource,
  });
}

AppDataSources createDataSources() {
  final apiClient = HotftpApiClient();

  return AppDataSources(
    apiClient: apiClient,
    firebaseAuthDatasource: FirebaseAuthDatasource(),
  );
}
