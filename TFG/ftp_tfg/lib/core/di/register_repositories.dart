import '../../data/repositories/firebase_auth_repository_impl.dart';
import '../../data/repositories/ftp_api_repository.dart';
import '../../data/repositories/monitoring_api_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/ftp_repository.dart' as domain_ftp;
import '../../domain/repositories/monitoring_repository.dart';
import 'register_datasources.dart';

class AppRepositories {
  final domain_ftp.FtpRepository ftpRepository;
  final MonitoringRepository monitoringRepository;
  final AuthRepository authRepository;

  AppRepositories({
    required this.ftpRepository,
    required this.monitoringRepository,
    required this.authRepository,
  });
}

AppRepositories createRepositories(AppDataSources dataSources) {
  return AppRepositories(
    ftpRepository: ApiFtpRepositoryImpl(dataSources.apiClient),
    monitoringRepository: ApiMonitoringRepository(dataSources.apiClient),
    authRepository: FirebaseAuthRepositoryImpl(dataSources.firebaseAuthDatasource),
  );
}
