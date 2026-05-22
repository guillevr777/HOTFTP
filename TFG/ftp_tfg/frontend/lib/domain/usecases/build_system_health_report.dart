import '../entities/file_version.dart';
import '../entities/system_alert.dart';
import '../entities/system_event.dart';
import '../entities/system_health_summary.dart';
import '../entities/system_recommendation.dart';
import '../entities/system_usage_stats.dart';
import '../entities/sync_record.dart';
import '../interfaces/i_build_system_health_report_use_case.dart';

class BuildSystemHealthReport implements IBuildSystemHealthReportUseCase {
  const BuildSystemHealthReport();

  @override
  String execute({
    required SystemHealthSummary summary,
    required List<SystemEvent> recentEvents,
    required List<SystemAlert> activeAlerts,
    required List<SyncRecord> recentSyncs,
    required List<FileVersion> recentFileVersions,
    required List<SystemRecommendation> recommendations,
    required SystemUsageStats? usageStats,
    required DateTime generatedAt,
  }) {
    final buffer = StringBuffer()
      ..writeln('HOTFTP - Informe técnico')
      ..writeln('Generado: ${generatedAt.toIso8601String()}')
      ..writeln()
      ..writeln('Resumen general')
      ..writeln('- Estado: ${summary.statusLabel}')
      ..writeln('- Perfiles: ${summary.totalProfiles}')
      ..writeln('- Sincronizaciones: ${summary.totalSyncs}')
      ..writeln('- Alertas activas: ${summary.unresolvedAlerts}')
      ..writeln('- Sincronizaciones con error: ${summary.errorSyncs}')
      ..writeln(
        '- Última sincronización: ${summary.lastSyncAt?.toIso8601String() ?? 'Sin datos'}',
      )
      ..writeln(
        '- Último evento: ${summary.lastEventAt?.toIso8601String() ?? 'Sin datos'}',
      )
      ..writeln();

    if (usageStats != null) {
      buffer
        ..writeln('Patrones de uso')
        ..writeln(
          '- Tasa de éxito: ${(usageStats.successRate * 100).toStringAsFixed(0)}%',
        )
        ..writeln('- Sincronizaciones correctas: ${usageStats.successfulSyncs}')
        ..writeln('- Fallos: ${usageStats.failedSyncs}')
        ..writeln(
          '- Media de archivos transferidos: ${usageStats.averageFilesTransferred.toStringAsFixed(1)}',
        )
        ..writeln(
          '- Hora pico: ${usageStats.peakHour == null ? 'Sin datos' : '${usageStats.peakHour!.toString().padLeft(2, '0')}:00'}',
        )
        ..writeln(
          '- Perfil más activo: ${usageStats.topProfileName ?? 'Sin datos'}',
        )
        ..writeln(
          '- Sincronizaciones del perfil principal: ${usageStats.topProfileSyncs}',
        )
        ..writeln();
    }

    buffer
      ..writeln('Alertas activas (${activeAlerts.length})')
      ..writeln(
        activeAlerts.isEmpty
            ? '- Sin alertas pendientes'
            : activeAlerts
                  .map(
                    (alert) =>
                        '- [${alert.severity.name}] ${alert.title} :: ${alert.message}',
                  )
                  .join('\n'),
      )
      ..writeln()
      ..writeln('Eventos recientes (${recentEvents.length})')
      ..writeln(
        recentEvents.isEmpty
            ? '- Sin eventos'
            : recentEvents
                  .map(
                    (event) =>
                        '- [${event.severity.name}] ${event.title} :: ${event.message}',
                  )
                  .join('\n'),
      )
      ..writeln()
      ..writeln('Versiones recientes (${recentFileVersions.length})')
      ..writeln(
        recentFileVersions.isEmpty
            ? '- Sin versiones registradas'
            : recentFileVersions
                  .map(
                    (version) =>
                        '- v${version.versionNumber} ${version.fileName} (${version.source}, ${version.size} bytes)',
                  )
                  .join('\n'),
      )
      ..writeln()
      ..writeln('Sincronizaciones recientes (${recentSyncs.length})')
      ..writeln(
        recentSyncs.isEmpty
            ? '- Sin sincronizaciones'
            : recentSyncs
                  .map(
                    (sync) =>
                        '- ${sync.date.toIso8601String()} :: ${sync.mode} :: ${sync.filesTransferred} transferidos, ${sync.filesSkipped} omitidos',
                  )
                  .join('\n'),
      )
      ..writeln()
      ..writeln('Recomendaciones (${recommendations.length})')
      ..writeln(
        recommendations.isEmpty
            ? '- Sin recomendaciones'
            : recommendations
                  .map(
                    (recommendation) =>
                        '- ${recommendation.title}: ${recommendation.message}',
                  )
                  .join('\n'),
      );

    return buffer.toString();
  }
}




