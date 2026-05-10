import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/file_version.dart';
import '../../../domain/entities/system_alert.dart';
import '../../../domain/entities/system_event.dart';
import '../../../domain/entities/system_health_summary.dart';
import '../../../domain/entities/system_recommendation.dart';
import '../../../domain/entities/system_usage_stats.dart';
import '../../../theme/app_theme.dart';
import '../../viewmodels/system_health_view_model.dart';
import 'file_version_history_screen.dart';
import '../../../domain/interfaces/i_acknowledge_alert_use_case.dart';
import '../../../domain/interfaces/i_analyze_system_usage_use_case.dart';
import '../../../domain/interfaces/i_build_system_health_report_use_case.dart';
import '../../../domain/interfaces/i_generate_system_recommendations_use_case.dart';
import '../../../domain/interfaces/i_get_active_alerts_use_case.dart';
import '../../../domain/interfaces/i_get_health_summary_use_case.dart';
import '../../../domain/interfaces/i_get_profiles_use_case.dart';
import '../../../domain/interfaces/i_get_recent_events_use_case.dart';
import '../../../domain/interfaces/i_get_recent_file_versions_use_case.dart';
import '../../../domain/interfaces/i_get_recent_syncs_use_case.dart';

class HealthCenterScreen extends StatelessWidget {
  final String ownerId;

  const HealthCenterScreen({
    super.key,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SystemHealthViewModel(
        getHealthSummary: context.read<IGetHealthSummaryUseCase>(),
        getRecentEvents: context.read<IGetRecentEventsUseCase>(),
        getActiveAlerts: context.read<IGetActiveAlertsUseCase>(),
        getRecentSyncs: context.read<IGetRecentSyncsUseCase>(),
        getRecentFileVersions: context.read<IGetRecentFileVersionsUseCase>(),
        getProfiles: context.read<IGetProfilesUseCase>(),
        acknowledgeAlert: context.read<IAcknowledgeAlertUseCase>(),
        ownerId: ownerId,
        buildSystemHealthReport:
            context.read<IBuildSystemHealthReportUseCase>(),
        generateSystemRecommendations:
            context.read<IGenerateSystemRecommendationsUseCase>(),
        analyzeSystemUsage: context.read<IAnalyzeSystemUsageUseCase>(),
      )..load(),
      child: _HealthCenterBody(ownerId: ownerId),
    );
  }
}

class _HealthCenterBody extends StatelessWidget {
  final String ownerId;

  const _HealthCenterBody({required this.ownerId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SystemHealthViewModel>();
    final summary = vm.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de salud'),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Exportar informe',
            onPressed: vm.isLoading
                ? null
                : () async {
                    final ok = await vm.exportHealthReport();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Informe generado en ${vm.lastExportPath}'
                              : vm.error ?? 'No se pudo generar el informe',
                        ),
                        backgroundColor: ok ? AppTheme.success : AppTheme.error,
                      ),
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.isLoading ? null : vm.load,
          ),
        ],
      ),
      body: vm.isLoading && summary == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: vm.load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (vm.error != null) ...[
                    _Banner(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      icon: Icons.error_outline,
                      text: vm.error!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (vm.lastExportPath != null) ...[
                    _Banner(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      icon: Icons.check_circle_outline,
                      text: 'Ãšltimo informe exportado en ${vm.lastExportPath}',
                    ),
                    const SizedBox(height: 16),
                  ],
                  _StatusCard(summary: summary),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'EstadÃ­sticas y patrones',
                    subtitle:
                        'AnÃ¡lisis de uso para apoyar decisiones automÃ¡ticas',
                  ),
                  const SizedBox(height: 8),
                  if (vm.usageStats == null)
                    const _EmptyState(text: 'TodavÃ­a no hay suficientes datos')
                  else
                    _UsageStatsCard(stats: vm.usageStats!),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'Recomendaciones inteligentes',
                    subtitle: 'Sugerencias basadas en tus sincronizaciones',
                  ),
                  const SizedBox(height: 8),
                  if (vm.recommendations.isEmpty)
                    const _EmptyState(text: 'TodavÃ­a no hay recomendaciones')
                  else
                    ...vm.recommendations.map(
                      (recommendation) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecommendationCard(
                          recommendation: recommendation,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'Versionado reciente',
                    subtitle: 'Cambios detectados en archivos remotos',
                  ),
                  const SizedBox(height: 8),
                  if (vm.recentFileVersions.isEmpty)
                    const _EmptyState(
                      text: 'TodavÃ­a no hay versiones registradas',
                    )
                  else
                    ...vm.recentFileVersions.map(
                      (version) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _VersionCard(
                          version: version,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FileVersionHistoryScreen(
                                ownerId: ownerId,
                                profileId: version.profileId,
                                filePath: version.filePath,
                                fileName: version.fileName,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'Alertas activas',
                    subtitle: 'SeÃ±ales que requieren revisiÃ³n',
                  ),
                  const SizedBox(height: 8),
                  if (vm.activeAlerts.isEmpty)
                    const _EmptyState(text: 'No hay alertas pendientes')
                  else
                    ...vm.activeAlerts.map(
                      (alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AlertCard(
                          alert: alert,
                          onAcknowledge: () => vm.acknowledgeAlert(alert),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'Actividad reciente',
                    subtitle: 'AuditorÃ­a tÃ©cnica de sincronizaciÃ³n y eventos',
                  ),
                  const SizedBox(height: 8),
                  if (vm.recentEvents.isEmpty)
                    const _EmptyState(text: 'TodavÃ­a no hay eventos')
                  else
                    ...vm.recentEvents.map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _EventCard(
                          event: event,
                          formatDateTime: vm.formatDateTime,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SystemHealthSummary? summary;

  const _StatusCard({required this.summary});

  Color _statusColor() {
    if (summary == null) return AppTheme.onSurfaceMuted;
    if (summary!.hasRiskSignals) return AppTheme.warning;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: color),
                const SizedBox(width: 10),
                const Text(
                  'Estado general',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              summary?.statusLabel ?? 'Sin datos',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(
                  label: 'Perfiles',
                  value: '${summary?.totalProfiles ?? 0}',
                ),
                _MetricChip(
                  label: 'Syncs',
                  value: '${summary?.totalSyncs ?? 0}',
                ),
                _MetricChip(
                  label: 'Alertas',
                  value: '${summary?.totalAlerts ?? 0}',
                ),
                _MetricChip(
                  label: 'Pendientes',
                  value: '${summary?.unresolvedAlerts ?? 0}',
                ),
              ],
            ),
            if (summary?.lastSyncAt != null ||
                summary?.lastEventAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Ãšltima sincronizaciÃ³n: ${summary?.lastSyncAt != null ? summary!.lastSyncAt!.toLocal() : 'Sin datos'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ãšltimo evento: ${summary?.lastEventAt != null ? summary!.lastEventAt!.toLocal() : 'Sin datos'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _Banner({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text),
      ),
    );
  }
}

class _UsageStatsCard extends StatelessWidget {
  final SystemUsageStats stats;

  const _UsageStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Ã‰xito: ${(stats.successRate * 100).toStringAsFixed(0)}%, perfil top: ${stats.topProfileName ?? 'Sin datos'}',
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final SystemRecommendation recommendation;

  const _RecommendationCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(recommendation.title),
        subtitle: Text(recommendation.message),
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  final FileVersion version;
  final VoidCallback onTap;

  const _VersionCard({required this.version, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(version.fileName),
        subtitle: Text(version.filePath),
        onTap: onTap,
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final SystemAlert alert;
  final VoidCallback onAcknowledge;

  const _AlertCard({required this.alert, required this.onAcknowledge});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(alert.title),
        subtitle: Text(alert.message),
        trailing: TextButton(
          onPressed: onAcknowledge,
          child: const Text('OK'),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final SystemEvent event;
  final String Function(DateTime) formatDateTime;

  const _EventCard({required this.event, required this.formatDateTime});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(event.message),
      ),
    );
  }
}




