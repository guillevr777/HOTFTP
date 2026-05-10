import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../domain/interfaces/i_evaluate_sync_rules_use_case.dart';
import '../../domain/repositories/ftp_repository.dart' as domain_ftp;
import '../../domain/repositories/monitoring_repository.dart';
import 'register_datasources.dart';
import 'register_repositories.dart';
import 'register_services.dart';
import 'register_usecases.dart';
import 'register_viewmodels.dart';

class AppDependencies {
  final domain_ftp.FtpRepository ftpRepository;
  final MonitoringRepository monitoringRepository;
  final IEvaluateSyncRulesUseCase evaluateSyncRules;
  final List<SingleChildWidget> providers;

  AppDependencies._({
    required this.ftpRepository,
    required this.monitoringRepository,
    required this.evaluateSyncRules,
    required this.providers,
  });

  factory AppDependencies.create() {
    final dataSources = createDataSources();
    final repositories = createRepositories(dataSources);
    final useCases = createUseCases(repositories);
    final serviceProviders = createServiceProviders(repositories);
    final viewModelProviders = createViewModelProviders(useCases);

    return AppDependencies._(
      ftpRepository: repositories.ftpRepository,
      monitoringRepository: repositories.monitoringRepository,
      evaluateSyncRules: useCases.evaluateSyncRules,
      providers: [
        Provider<domain_ftp.FtpRepository>.value(value: repositories.ftpRepository),
        Provider<MonitoringRepository>.value(value: repositories.monitoringRepository),
        ...createUseCaseProviders(useCases),
        ...serviceProviders,
        ...viewModelProviders,
      ],
    );
  }
}
