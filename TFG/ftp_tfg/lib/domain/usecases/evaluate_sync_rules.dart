import '../entities/system_alert.dart';
import '../entities/sync_record.dart';

class EvaluateSyncRules {
  const EvaluateSyncRules();

  List<SystemAlert> execute({
    required String ownerId,
    required int profileId,
    required String profileName,
    required List<SyncRecord> recentSyncs,
    required List<SystemAlert> activeAlerts,
    DateTime? now,
  }) {
    final alerts = <SystemAlert>[];
    final failureAlert = _consecutiveFailureAlert(
      ownerId: ownerId,
      profileId: profileId,
      profileName: profileName,
      recentSyncs: recentSyncs,
      activeAlerts: activeAlerts,
      now: now ?? DateTime.now(),
    );
    if (failureAlert != null) {
      alerts.add(failureAlert);
    }
    return alerts;
  }

  SystemAlert? _consecutiveFailureAlert({
    required String ownerId,
    required int profileId,
    required String profileName,
    required List<SyncRecord> recentSyncs,
    required List<SystemAlert> activeAlerts,
    required DateTime now,
  }) {
    final profileSyncs = recentSyncs
        .where((sync) => sync.profileId == profileId)
        .toList(growable: false);
    if (profileSyncs.length < 3) return null;

    final lastThree = profileSyncs.take(3).toList(growable: false);
    final allFailed = lastThree.every(
      (sync) => (sync.errorMessage ?? '').trim().isNotEmpty,
    );
    if (!allFailed) return null;

    final alreadyActive = activeAlerts.any(
      (alert) =>
          alert.ownerId == ownerId &&
          alert.relatedProfileId == profileId &&
          alert.source == 'auto-rule' &&
          alert.title == 'Tres sincronizaciones seguidas con error' &&
          alert.resolvedAt == null,
    );
    if (alreadyActive) return null;

    return SystemAlert(
      ownerId: ownerId,
      source: 'auto-rule',
      severity: SystemAlertSeverity.warning,
      title: 'Tres sincronizaciones seguidas con error',
      message:
          'El perfil "$profileName" acumula 3 sincronizaciones fallidas seguidas. Revisa credenciales, conectividad o la ruta remota.',
      relatedProfileId: profileId,
      createdAt: now,
    );
  }
}
