import 'package:flutter/material.dart';

import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

import '../../core/services/android_storage_access.dart';
import '../../core/services/dump_schedule_background_service.dart';
import '../../domain/entities/dump_schedule.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/system_event.dart';
import '../../domain/interfaces/i_record_event_use_case.dart';
import '../../domain/interfaces/i_get_dump_schedule_for_profile_use_case.dart';
import '../../domain/interfaces/i_save_dump_schedule_use_case.dart';

class DumpScheduleViewModel extends ChangeNotifier {
  final IGetDumpScheduleForProfileUseCase getDumpScheduleForProfile;
  final ISaveDumpScheduleUseCase saveDumpSchedule;
  final IRecordEventUseCase recordEvent;
  final FtpProfile profile;
  final String ownerId;
  final DumpScheduleBackgroundService backgroundService;

  static String get _defaultLocalPath =>
      Platform.isAndroid ? '/storage/emulated/0' : Directory.current.path;

  DumpScheduleViewModel({
    required this.getDumpScheduleForProfile,
    required this.saveDumpSchedule,
    required this.recordEvent,
    required this.profile,
    required this.ownerId,
    this.backgroundService = const DumpScheduleBackgroundService(),
  });

  DumpSchedule? schedule;
  bool isLoading = false;
  bool isSaving = false;
  String? error;
  String? successMessage;

  bool enabled = false;
  String localPath = _defaultLocalPath;
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
      schedule = await getDumpScheduleForProfile.execute(ownerId, profile);
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
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      localPath = _defaultLocalPath;
    } else if (Platform.isAndroid && !trimmed.startsWith('/')) {
      localPath = p.normalize('/$trimmed');
    } else {
      localPath = p.normalize(trimmed);
    }
    notifyListeners();
  }

  void setRemotePath(String value) {
    remotePath = _normalizeRemotePath(value);
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

  void copyFromManual({
    required String manualLocalPath,
    required String manualRemotePath,
    required DumpSourceSide manualSourceSide,
    required DumpTransferMode manualTransferMode,
  }) {
    localPath = manualLocalPath.trim().isEmpty
        ? _defaultLocalPath
        : manualLocalPath.trim();
    remotePath = _normalizeRemotePath(manualRemotePath);
    sourceSide = manualSourceSide;
    transferMode = manualTransferMode;
    enabled = true;
    notifyListeners();
  }

  String _normalizeRemotePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '/') return '/';
    final normalized = p.posix.normalize(
      trimmed.startsWith('/') ? trimmed : '/$trimmed',
    );
    return normalized == '.' || normalized.isEmpty ? '/' : normalized;
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
      if (enabled) {
        final hasAccess = await AndroidStorageAccess.ensureScheduledDumpAccess();
        if (!hasAccess) {
          error =
              'No se pudo activar el volcado programado porque faltan permisos de archivos o bateria.';
          return;
        }
      }

      final isNewSchedule = schedule?.id == null;
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

      final id = await saveDumpSchedule.execute(updated, profile);
      schedule = updated.copyWith(id: id);
      if (enabled) {
        await backgroundService.schedule(schedule!, profile);
      } else {
        await backgroundService.cancel(schedule!);
      }
      successMessage = enabled
          ? 'Volcado recurrente guardado'
          : 'Volcado recurrente desactivado';
      await _trackEvent(
        eventType: isNewSchedule
            ? 'schedule_created'
            : enabled
            ? 'schedule_updated'
            : 'schedule_disabled',
        severity: enabled ? SystemEventSeverity.success : SystemEventSeverity.warning,
        title: isNewSchedule
            ? 'Programación creada'
            : enabled
            ? 'Programación actualizada'
            : 'Programación desactivada',
        message: enabled
            ? 'Se guardó una sincronización programada para "${profile.name}" cada $intervalValue ${_intervalUnitLabel(intervalUnit)}.'
            : 'Se desactivó la sincronización programada de "${profile.name}".',
      );
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

  Future<void> _trackEvent({
    required String eventType,
    required SystemEventSeverity severity,
    required String title,
    required String message,
  }) async {
    try {
      await recordEvent.execute(
        SystemEvent(
          ownerId: ownerId,
          eventType: eventType,
          severity: severity,
          title: title,
          message: message,
          relatedProfileId: profile.id,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // La programación no debe romper la experiencia del usuario.
    }
  }

  String _intervalUnitLabel(DumpIntervalUnit unit) {
    return switch (unit) {
      DumpIntervalUnit.minutes => 'minuto${intervalValue == 1 ? '' : 's'}',
      DumpIntervalUnit.hours => 'hora${intervalValue == 1 ? '' : 's'}',
      DumpIntervalUnit.days => 'día${intervalValue == 1 ? '' : 's'}',
    };
  }
}
