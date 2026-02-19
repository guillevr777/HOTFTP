class SyncRecord {
  final int? id;
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
        'id': id,
        'profileId': profileId,
        'date': date.toIso8601String(),
        'localPath': localPath,
        'remotePath': remotePath,
        'mode': mode,
        'filesTransferred': filesTransferred,
        'filesSkipped': filesSkipped,
        'errorMessage': errorMessage,
      };

  factory SyncRecord.fromMap(Map<String, dynamic> map) => SyncRecord(
        id: map['id'],
        profileId: map['profileId'],
        date: DateTime.parse(map['date']),
        localPath: map['localPath'],
        remotePath: map['remotePath'],
        mode: map['mode'],
        filesTransferred: map['filesTransferred'] ?? 0,
        filesSkipped: map['filesSkipped'] ?? 0,
        errorMessage: map['errorMessage'],
      );
}
