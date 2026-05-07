import 'package:flutter/material.dart';

import '../../domain/entities/dump_schedule.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/repositories/ftp_repository.dart';

class DumpScheduleViewModel extends ChangeNotifier {
  final FtpRepository repository;
  final FtpProfile profile;
  final String ownerId;

  DumpScheduleViewModel({
    required this.repository,
    required this.profile,
    required this.ownerId,
  });

  DumpSchedule? schedule;
  bool isLoading = false;
  bool isSaving = false;
  String? error;
  String? successMessage;

  bool enabled = false;
  String localPath = '/storage/emulated/0/Download';
  String remotePath = '/';
  DumpSourceSide sourceSide = DumpSourceSide.local;
  DumpTransferMode transferMode = DumpTransferMode.oneWay;
  bool deleteSourceAfterCopy = false;
  int intervalValue = 24;
  DumpIntervalUnit intervalUnit = DumpIntervalUnit.hours;

  Future<void> loadSchedule() async {
    if (profile.id == null) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      schedule = await repository.getDumpScheduleForProfile(
        ownerId,
        profile.id!,
      );
      if (schedule != null) {
        enabled = schedule!.enabled;
        localPath = schedule!.localPath;
        remotePath = schedule!.remotePath;
        sourceSide = schedule!.sourceSide;
        transferMode = schedule!.transferMode;
        deleteSourceAfterCopy = schedule!.deleteSourceAfterCopy;
        intervalValue = schedule!.intervalValue;
        intervalUnit = schedule!.intervalUnit;
      }
    } catch (e) {
      error = 'No se pudo cargar la programacion: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setEnabled(bool value) {
    enabled = value;
    notifyListeners();
  }

  void setLocalPath(String value) {
    localPath = value;
    notifyListeners();
  }

  void setRemotePath(String value) {
    remotePath = value;
    notifyListeners();
  }

  void setSourceSide(DumpSourceSide value) {
    sourceSide = value;
    notifyListeners();
  }

  void setTransferMode(DumpTransferMode value) {
    transferMode = value;
    notifyListeners();
  }

  void setDeleteSourceAfterCopy(bool value) {
    deleteSourceAfterCopy = value;
    notifyListeners();
  }

  void setIntervalValue(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) return;
    intervalValue = parsed;
    notifyListeners();
  }

  void setIntervalUnit(DumpIntervalUnit value) {
    intervalUnit = value;
    notifyListeners();
  }

  Future<void> saveSchedule() async {
    if (profile.id == null) {
      error = 'El perfil debe guardarse antes de programar un volcado.';
      notifyListeners();
      return;
    }
    isSaving = true;
    error = null;
    successMessage = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final nextRun = enabled
          ? DumpSchedule(
              ownerId: ownerId,
              profileId: profile.id!,
              enabled: enabled,
              localPath: localPath,
              remotePath: remotePath,
              sourceSide: sourceSide,
              transferMode: transferMode,
              deleteSourceAfterCopy: deleteSourceAfterCopy,
              intervalValue: intervalValue,
              intervalUnit: intervalUnit,
            ).calculateNextRun(now)
          : null;

      final updated = DumpSchedule(
        id: schedule?.id,
        ownerId: ownerId,
        profileId: profile.id!,
        enabled: enabled,
        localPath: localPath,
        remotePath: remotePath,
        sourceSide: sourceSide,
        transferMode: transferMode,
        deleteSourceAfterCopy: deleteSourceAfterCopy,
        intervalValue: intervalValue,
        intervalUnit: intervalUnit,
        lastRunAt: schedule?.lastRunAt,
        nextRunAt: nextRun,
      );

      final id = await repository.saveDumpSchedule(updated);
      schedule = updated.copyWith(id: id);
      successMessage = enabled
          ? 'Volcado recurrente guardado'
          : 'Volcado recurrente desactivado';
    } catch (e) {
      error = 'No se pudo guardar la programacion: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    error = null;
    successMessage = null;
    notifyListeners();
  }
}
