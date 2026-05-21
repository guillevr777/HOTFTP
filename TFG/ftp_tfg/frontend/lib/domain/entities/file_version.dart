class FileVersion {
  final int? id;
  final String ownerId;
  final int profileId;
  final String filePath;
  final String fileName;
  final int versionNumber;
  final int size;
  final DateTime? modifiedAt;
  final String source;
  final DateTime createdAt;

  const FileVersion({
    this.id,
    required this.ownerId,
    required this.profileId,
    required this.filePath,
    required this.fileName,
    required this.versionNumber,
    required this.size,
    required this.modifiedAt,
    required this.source,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'profileId': profileId,
    'filePath': filePath,
    'fileName': fileName,
    'versionNumber': versionNumber,
    'size': size,
    'source': source,
    'createdAt': createdAt.toIso8601String(),
    if (id != null) 'id': id,
    if (modifiedAt != null) 'modifiedAt': modifiedAt!.toIso8601String(),
  };

  factory FileVersion.fromMap(Map<String, dynamic> map) => FileVersion(
    id: map['id'] as int?,
    ownerId: map['ownerId'] as String? ?? '',
    profileId: map['profileId'] as int,
    filePath: map['filePath'] as String? ?? '',
    fileName: map['fileName'] as String? ?? '',
    versionNumber: map['versionNumber'] as int? ?? 1,
    size: map['size'] as int? ?? 0,
    modifiedAt: map['modifiedAt'] == null
        ? null
        : DateTime.tryParse(map['modifiedAt'] as String),
    source: map['source'] as String? ?? 'remote',
    createdAt:
        DateTime.tryParse(map['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

