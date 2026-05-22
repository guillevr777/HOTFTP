import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:universal_io/io.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/datasources/ftp_real_datasource.dart';
import '../../data/datasources/hotftp_api_client.dart';
import '../../data/repositories/ftp_api_repository.dart';
import '../../data/repositories/ftp_repository.dart';
import '../../data/repositories/hybrid_ftp_repository.dart';
import '../../domain/entities/dump_schedule.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/entities/sync_record.dart';
import '../../domain/repositories/ftp_repository.dart' as domain_ftp;
import 'android_storage_access.dart';
import 'dump_transfer_service.dart';

const String _scheduledDumpTaskName = 'hotftp.scheduled_dump.run';
const String _scheduledDumpTag = 'hotftp.scheduled_dump';

@pragma('vm:entry-point')
void dumpScheduleCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (taskName != _scheduledDumpTaskName || inputData == null) return true;

    try {
      final runner = _ScheduledDumpRunner(_createBackgroundRepository());
      await runner.run(inputData);
      return true;
    } catch (error, stackTrace) {
      debugPrint('HOTFTP scheduled dump failed: $error\n$stackTrace');
      return true;
    }
  });
}

class DumpScheduleBackgroundService {
  static bool _initialized = false;

  const DumpScheduleBackgroundService();

  Future<void> initialize() async {
    if (!_isSupported || _initialized) return;
    await Workmanager().initialize(dumpScheduleCallbackDispatcher);
    _initialized = true;
  }

  Future<void> schedule(DumpSchedule schedule, FtpProfile profile) async {
    if (!_isSupported) return;
    await initialize();

    final uniqueName = _uniqueTaskName(schedule.ownerId, schedule.profileId);
    if (!schedule.enabled || schedule.nextRunAt == null) {
      await Workmanager().cancelByUniqueName(uniqueName);
      return;
    }

    await Workmanager().registerOneOffTask(
      uniqueName,
      _scheduledDumpTaskName,
      inputData: _serializeInput(schedule, profile),
      initialDelay: _delayUntil(schedule.nextRunAt!),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      tag: _scheduledDumpTag,
    );
  }

  Future<void> cancel(DumpSchedule schedule) async {
    if (!_isSupported) return;
    await initialize();
    await Workmanager().cancelByUniqueName(
      _uniqueTaskName(schedule.ownerId, schedule.profileId),
    );
  }

  static bool get _isSupported => !kIsWeb && Platform.isAndroid;
}

class _ScheduledDumpRunner {
  final domain_ftp.FtpRepository repository;
  final DumpTransferService transferService;
  final DumpScheduleBackgroundService scheduler;

  _ScheduledDumpRunner(this.repository)
    : transferService = DumpTransferService(repository),
      scheduler = const DumpScheduleBackgroundService();

  Future<void> run(Map<String, dynamic> inputData) async {
    final schedule = _scheduleFromInput(inputData);
    final profile = _profileFromInput(inputData);
    if (!schedule.enabled) return;

    var errorMessage = '';
    DumpTransferResult? result;

    final hasAccess = await AndroidStorageAccess.ensureSharedStorageAccess(
      openSettingsIfDenied: false,
    );

    try {
      if (!hasAccess) {
        throw FileSystemException(
          'Permiso de almacenamiento no disponible para el volcado programado',
          schedule.localPath,
        );
      }

      result = await transferService.execute(
        profile: profile,
        localPath: schedule.localPath,
        remotePath: schedule.remotePath,
        transferMode: schedule.transferMode,
        sourceSide: schedule.sourceSide,
        deleteSourceAfterCopy: schedule.deleteSourceAfterCopy,
      );
    } catch (error) {
      errorMessage = error.toString();
    }

    await _saveSyncRecord(
      schedule: schedule,
      profile: profile,
      result: result,
      errorMessage: errorMessage.isEmpty ? null : errorMessage,
    );

    final completedAt = DateTime.now();
    final nextSchedule = schedule.copyWith(
      lastRunAt: completedAt,
      nextRunAt: schedule.calculateNextRun(completedAt),
    );
    await _saveSchedule(nextSchedule, profile);
    await scheduler.schedule(nextSchedule, profile);
  }

  Future<void> _saveSyncRecord({
    required DumpSchedule schedule,
    required FtpProfile profile,
    required DumpTransferResult? result,
    required String? errorMessage,
  }) async {
    try {
      await repository.saveSyncRecord(
        SyncRecord(
          ownerId: schedule.ownerId,
          profileId: schedule.profileId,
          date: DateTime.now(),
          localPath: schedule.localPath,
          remotePath: schedule.remotePath,
          mode: schedule.transferMode.name,
          filesTransferred: result?.transferred ?? 0,
          filesSkipped: result?.skipped ?? 0,
          errorMessage: errorMessage,
        ),
        profile,
      );
    } catch (error) {
      debugPrint('HOTFTP: could not save scheduled sync record -> $error');
    }
  }

  Future<void> _saveSchedule(
    DumpSchedule schedule,
    FtpProfile profile,
  ) async {
    try {
      await repository.saveDumpSchedule(schedule, profile);
    } catch (error) {
      debugPrint('HOTFTP: could not update scheduled dump dates -> $error');
    }
  }
}

domain_ftp.FtpRepository _createBackgroundRepository() {
  final localRepository = FtpRepositoryImpl(FtpRealDatasource());
  final remoteRepository = ApiFtpRepositoryImpl(HotftpApiClient());
  return HybridFtpRepositoryImpl(
    localRepository: localRepository,
    remoteRepository: remoteRepository,
  );
}

Map<String, dynamic> _serializeInput(
  DumpSchedule schedule,
  FtpProfile profile,
) {
  return {
    'scheduleId': schedule.id ?? 0,
    'ownerId': schedule.ownerId,
    'profileId': schedule.profileId,
    'enabled': schedule.enabled,
    'localPath': schedule.localPath,
    'remotePath': schedule.remotePath,
    'sourceSide': schedule.sourceSide.name,
    'transferMode': schedule.transferMode.name,
    'deleteSourceAfterCopy': schedule.deleteSourceAfterCopy,
    'intervalValue': schedule.intervalValue,
    'intervalUnit': schedule.intervalUnit.name,
    'lastRunAt': schedule.lastRunAt?.toUtc().toIso8601String() ?? '',
    'nextRunAt': schedule.nextRunAt?.toUtc().toIso8601String() ?? '',
    'profileOwnerId': profile.ownerId ?? schedule.ownerId,
    'profileTransportType': profile.transportType.name,
    'profileProtocol': profile.protocol.name,
    'profileName': profile.name,
    'profileHost': profile.host,
    'profilePort': profile.port,
    'profileUsername': profile.username,
    'profilePassword': profile.password,
    'profilePassiveMode': profile.passiveMode,
  };
}

DumpSchedule _scheduleFromInput(Map<String, dynamic> input) {
  DateTime? optionalDate(String key) {
    final raw = '${input[key] ?? ''}'.trim();
    return raw.isEmpty ? null : DateTime.tryParse(raw);
  }

  return DumpSchedule(
    id: _positiveIntValue(input['scheduleId']),
    ownerId: '${input['ownerId'] ?? ''}',
    profileId: _intValue(input['profileId']) ?? 0,
    enabled: _boolValue(input['enabled']),
    localPath: '${input['localPath'] ?? ''}',
    remotePath: '${input['remotePath'] ?? '/'}',
    sourceSide: DumpSourceSide.values.firstWhere(
      (value) => value.name == input['sourceSide'],
      orElse: () => DumpSourceSide.local,
    ),
    transferMode: DumpTransferMode.values.firstWhere(
      (value) => value.name == input['transferMode'],
      orElse: () => DumpTransferMode.oneWay,
    ),
    deleteSourceAfterCopy: _boolValue(input['deleteSourceAfterCopy']),
    intervalValue: _intValue(input['intervalValue']) ?? 24,
    intervalUnit: DumpIntervalUnit.values.firstWhere(
      (value) => value.name == input['intervalUnit'],
      orElse: () => DumpIntervalUnit.hours,
    ),
    lastRunAt: optionalDate('lastRunAt'),
    nextRunAt: optionalDate('nextRunAt'),
  );
}

FtpProfile _profileFromInput(Map<String, dynamic> input) {
  return FtpProfile.fromMap({
    'id': _intValue(input['profileId']),
    'ownerId': input['profileOwnerId'],
    'transportType': input['profileTransportType'],
    'protocol': input['profileProtocol'],
    'name': input['profileName'],
    'host': input['profileHost'],
    'port': _intValue(input['profilePort']) ?? 21,
    'username': input['profileUsername'],
    'password': input['profilePassword'],
    'passiveMode': input['profilePassiveMode'],
  });
}

Duration _delayUntil(DateTime target) {
  final delay = target.difference(DateTime.now());
  return delay.isNegative ? Duration.zero : delay;
}

String _uniqueTaskName(String ownerId, int profileId) {
  return 'hotftp.scheduled_dump.$ownerId.$profileId';
}

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}');
}

int? _positiveIntValue(Object? value) {
  final parsed = _intValue(value);
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}

bool _boolValue(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return '${value ?? ''}'.toLowerCase() == 'true';
}
