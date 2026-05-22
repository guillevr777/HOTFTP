enum DumpSourceSide { local, remote }

enum DumpTransferMode { oneWay, syncBoth }

enum DumpIntervalUnit { minutes, hours, days }

class DumpSchedule {
  final int? id;
  final String ownerId;
  final int profileId;
  final bool enabled;
  final String localPath;
  final String remotePath;
  final DumpSourceSide sourceSide;
  final DumpTransferMode transferMode;
  final bool deleteSourceAfterCopy;
  final int intervalValue;
  final DumpIntervalUnit intervalUnit;
  final DateTime? lastRunAt;
  final DateTime? nextRunAt;

  DumpSchedule({
    this.id,
    required this.ownerId,
    required this.profileId,
    required this.enabled,
    required this.localPath,
    required this.remotePath,
    required this.sourceSide,
    required this.transferMode,
    required this.deleteSourceAfterCopy,
    required this.intervalValue,
    required this.intervalUnit,
    this.lastRunAt,
    this.nextRunAt,
  });

  DumpSchedule copyWith({
    int? id,
    String? ownerId,
    int? profileId,
    bool? enabled,
    String? localPath,
    String? remotePath,
    DumpSourceSide? sourceSide,
    DumpTransferMode? transferMode,
    bool? deleteSourceAfterCopy,
    int? intervalValue,
    DumpIntervalUnit? intervalUnit,
    DateTime? lastRunAt,
    DateTime? nextRunAt,
  }) {
    return DumpSchedule(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      profileId: profileId ?? this.profileId,
      enabled: enabled ?? this.enabled,
      localPath: localPath ?? this.localPath,
      remotePath: remotePath ?? this.remotePath,
      sourceSide: sourceSide ?? this.sourceSide,
      transferMode: transferMode ?? this.transferMode,
      deleteSourceAfterCopy:
          deleteSourceAfterCopy ?? this.deleteSourceAfterCopy,
      intervalValue: intervalValue ?? this.intervalValue,
      intervalUnit: intervalUnit ?? this.intervalUnit,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      nextRunAt: nextRunAt ?? this.nextRunAt,
    );
  }

  DateTime calculateNextRun(DateTime from) {
    final duration = switch (intervalUnit) {
      DumpIntervalUnit.minutes => Duration(minutes: intervalValue),
      DumpIntervalUnit.hours => Duration(hours: intervalValue),
      DumpIntervalUnit.days => Duration(days: intervalValue),
    };
    return from.add(duration);
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'profileId': profileId,
    'enabled': enabled ? 1 : 0,
    'localPath': localPath,
    'remotePath': remotePath,
    'sourceSide': sourceSide.name,
    'transferMode': transferMode.name,
    'deleteSourceAfterCopy': deleteSourceAfterCopy ? 1 : 0,
    'intervalValue': intervalValue,
    'intervalUnit': intervalUnit.name,
    if (id != null) 'id': id,
    if (lastRunAt != null) 'lastRunAt': lastRunAt!.toUtc().toIso8601String(),
    if (nextRunAt != null) 'nextRunAt': nextRunAt!.toUtc().toIso8601String(),
  };

  factory DumpSchedule.fromMap(Map<String, dynamic> map) => DumpSchedule(
    id: map['id'] as int?,
    ownerId: map['ownerId'] as String? ?? '',
    profileId: map['profileId'] as int,
    enabled: map['enabled'] == true || map['enabled'] == 1,
    localPath: map['localPath'] as String? ?? '',
    remotePath: map['remotePath'] as String? ?? '/',
    sourceSide: DumpSourceSide.values.firstWhere(
      (value) => value.name == map['sourceSide'],
      orElse: () => DumpSourceSide.local,
    ),
    transferMode: DumpTransferMode.values.firstWhere(
      (value) => value.name == map['transferMode'],
      orElse: () => DumpTransferMode.oneWay,
    ),
    deleteSourceAfterCopy:
        map['deleteSourceAfterCopy'] == true ||
        map['deleteSourceAfterCopy'] == 1,
    intervalValue: map['intervalValue'] as int? ?? 24,
    intervalUnit: DumpIntervalUnit.values.firstWhere(
      (value) => value.name == map['intervalUnit'],
      orElse: () => DumpIntervalUnit.hours,
    ),
    lastRunAt: map['lastRunAt'] == null
        ? null
        : DateTime.tryParse(map['lastRunAt'] as String),
    nextRunAt: map['nextRunAt'] == null
        ? null
        : DateTime.tryParse(map['nextRunAt'] as String),
  );
}
