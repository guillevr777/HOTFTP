class SyncRecord {
  final int? id;
  final String ownerId;
  final int profileId;
  final DateTime date;
  final String localPath;
  final String remotePath;
  final String mode;
  final int filesTransferred;
  final int filesSkipped;
  final String? errorMessage;

  SyncRecord({
    this.id,
    required this.ownerId,
    required this.profileId,
    required this.date,
    required this.localPath,
    required this.remotePath,
    required this.mode,
    this.filesTransferred = 0,
    this.filesSkipped = 0,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'profileId': profileId,
    'date': date.toUtc().toIso8601String(),
    'localPath': localPath,
    'remotePath': remotePath,
    'mode': mode,
    'filesTransferred': filesTransferred,
    'filesSkipped': filesSkipped,
    if (id != null) 'id': id,
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory SyncRecord.fromMap(Map<String, dynamic> map) => SyncRecord(
    id: map['id'] as int?,
    ownerId: map['ownerId'] as String? ?? '',
    profileId: map['profileId'] as int,
    date: DateTime.parse(map['date'] as String),
    localPath: map['localPath'] as String,
    remotePath: map['remotePath'] as String,
    mode: map['mode'] as String,
    filesTransferred: map['filesTransferred'] as int? ?? 0,
    filesSkipped: map['filesSkipped'] as int? ?? 0,
    errorMessage: map['errorMessage'] as String?,
  );
}
