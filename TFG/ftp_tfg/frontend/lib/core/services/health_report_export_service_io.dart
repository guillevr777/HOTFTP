import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

class HealthReportExportService {
  const HealthReportExportService();

  Future<String> export(String content) async {
    final directory = await getApplicationDocumentsDirectory();
    final reportsDir = Directory(p.join(directory.path, 'hotftp_reports'));
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(reportsDir.path, 'health_report_$timestamp.txt'));
    await file.writeAsString(content);
    return file.path;
  }
}

