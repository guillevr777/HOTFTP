class SystemHealthSummary {
  final int totalProfiles;
  final int totalSyncs;
  final int totalAlerts;
  final int unresolvedAlerts;
  final int errorSyncs;
  final DateTime? lastSyncAt;
  final DateTime? lastEventAt;

  const SystemHealthSummary({
    required this.totalProfiles,
    required this.totalSyncs,
    required this.totalAlerts,
    required this.unresolvedAlerts,
    required this.errorSyncs,
    required this.lastSyncAt,
    required this.lastEventAt,
  });

  bool get hasRiskSignals => unresolvedAlerts > 0 || errorSyncs > 0;

  String get statusLabel {
    if (hasRiskSignals) return 'Necesita revisión';
    if (totalSyncs == 0) return 'Sin actividad';
    return 'Correcto';
  }
}
