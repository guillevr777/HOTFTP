enum SystemEventSeverity { info, success, warning, error }

class SystemEvent {
  final int? id;
  final String ownerId;
  final String eventType;
  final SystemEventSeverity severity;
  final String title;
  final String message;
  final int? relatedProfileId;
  final String? metadata;
  final DateTime createdAt;

  const SystemEvent({
    this.id,
    required this.ownerId,
    required this.eventType,
    required this.severity,
    required this.title,
    required this.message,
    this.relatedProfileId,
    this.metadata,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'eventType': eventType,
        'severity': severity.name,
        'title': title,
        'message': message,
        'relatedProfileId': relatedProfileId,
        'metadata': metadata,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SystemEvent.fromMap(Map<String, dynamic> map) => SystemEvent(
        id: map['id'] as int?,
        ownerId: map['ownerId'] as String? ?? '',
        eventType: map['eventType'] as String? ?? 'unknown',
        severity: SystemEventSeverity.values.firstWhere(
          (value) => value.name == map['severity'],
          orElse: () => SystemEventSeverity.info,
        ),
        title: map['title'] as String? ?? '',
        message: map['message'] as String? ?? '',
        relatedProfileId: map['relatedProfileId'] as int?,
        metadata: map['metadata'] as String?,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

