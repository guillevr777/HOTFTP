enum SystemAlertSeverity { info, warning, error }

class SystemAlert {
  final int? id;
  final String ownerId;
  final String source;
  final SystemAlertSeverity severity;
  final String title;
  final String message;
  final int? relatedProfileId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const SystemAlert({
    this.id,
    required this.ownerId,
    required this.source,
    required this.severity,
    required this.title,
    required this.message,
    this.relatedProfileId,
    this.isRead = false,
    required this.createdAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'source': source,
        'severity': severity.name,
        'title': title,
        'message': message,
        'relatedProfileId': relatedProfileId,
        'isRead': isRead ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  factory SystemAlert.fromMap(Map<String, dynamic> map) => SystemAlert(
        id: map['id'] as int?,
        ownerId: map['ownerId'] as String? ?? '',
        source: map['source'] as String? ?? 'system',
        severity: SystemAlertSeverity.values.firstWhere(
          (value) => value.name == map['severity'],
          orElse: () => SystemAlertSeverity.info,
        ),
        title: map['title'] as String? ?? '',
        message: map['message'] as String? ?? '',
        relatedProfileId: map['relatedProfileId'] as int?,
        isRead: map['isRead'] == 1,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        resolvedAt: map['resolvedAt'] == null
            ? null
            : DateTime.tryParse(map['resolvedAt'] as String),
      );
}
