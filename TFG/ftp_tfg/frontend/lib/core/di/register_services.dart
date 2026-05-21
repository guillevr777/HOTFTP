import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../services/dump_transfer_service.dart';
import '../services/health_report_export_service.dart';
import 'register_repositories.dart';

List<SingleChildWidget> createServiceProviders(AppRepositories repositories) {
  return [
    Provider<DumpTransferService>.value(
      value: DumpTransferService(repositories.ftpRepository),
    ),
    Provider<HealthReportExportService>.value(
      value: const HealthReportExportService(),
    ),
  ];
}
