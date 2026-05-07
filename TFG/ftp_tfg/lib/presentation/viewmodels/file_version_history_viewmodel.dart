import 'package:flutter/material.dart';

import '../../domain/entities/file_version.dart';
import '../../domain/repositories/monitoring_repository.dart';

class FileVersionHistoryViewModel extends ChangeNotifier {
  final MonitoringRepository repository;
  final String ownerId;
  final int profileId;
  final String filePath;

  FileVersionHistoryViewModel({
    required this.repository,
    required this.ownerId,
    required this.profileId,
    required this.filePath,
  });

  List<FileVersion> versions = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      versions = await repository.getFileVersionHistory(
        ownerId,
        profileId,
        filePath,
      );
    } catch (e) {
      error = 'No se pudo cargar el historial de versiones: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String formatDateTime(DateTime? dt) {
    if (dt == null) return 'Sin fecha';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
