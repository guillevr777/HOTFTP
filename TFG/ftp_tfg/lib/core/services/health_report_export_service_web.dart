import 'dart:html' as html;
import 'dart:convert';

import 'package:flutter/foundation.dart';

class HealthReportExportService {
  const HealthReportExportService();

  Future<String> export(String content) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'health_report_$timestamp.txt';
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'text/plain;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    debugPrint('HOTFTP: Report export triggered for $fileName');
    return fileName;
  }
}
