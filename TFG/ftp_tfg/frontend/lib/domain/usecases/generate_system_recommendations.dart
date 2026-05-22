import '../entities/system_alert.dart';
import '../entities/system_health_summary.dart';
import '../entities/system_recommendation.dart';
import '../entities/sync_record.dart';
import '../interfaces/i_generate_system_recommendations_use_case.dart';

class GenerateSystemRecommendations implements IGenerateSystemRecommendationsUseCase {
  const GenerateSystemRecommendations();

  @override
  List<SystemRecommendation> execute({
    required SystemHealthSummary summary,
    required List<SystemAlert> activeAlerts,
    required List<SyncRecord> recentSyncs,
  }) {
    final recommendations = <SystemRecommendation>[];

    if (summary.unresolvedAlerts > 0) {
      recommendations.add(
        const SystemRecommendation(
          title: 'Revisar alertas pendientes',
          message:
              'Tienes alertas sin resolver. Conviene revisarlas antes de lanzar nuevos backups.',
          kind: SystemRecommendationKind.action,
        ),
      );
    }

    if (summary.errorSyncs >= 3) {
      recommendations.add(
        const SystemRecommendation(
          title: 'Analizar fallos repetidos',
          message:
              'Se detectan varios errores de sincronización. Revisa credenciales, conectividad y permisos del servidor.',
          kind: SystemRecommendationKind.warning,
        ),
      );
    }

    if (summary.lastSyncAt == null) {
      recommendations.add(
        const SystemRecommendation(
          title: 'Configurar la primera sincronización',
          message:
              'Aún no hay sincronizaciones registradas. Crear una tarea automática te permitirá empezar a generar histórico útil.',
          kind: SystemRecommendationKind.action,
        ),
      );
    } else {
      final hoursSinceLastSync =
          DateTime.now().difference(summary.lastSyncAt!).inHours;
      if (hoursSinceLastSync >= 24) {
        recommendations.add(
          SystemRecommendation(
            title: 'Programar una sincronización',
            message:
                'La última sincronización fue hace $hoursSinceLastSync horas. Una tarea recurrente reduciría el riesgo de desactualización.',
            kind: SystemRecommendationKind.warning,
          ),
        );
      }
    }

    final syncHours = recentSyncs
        .where((record) => record.errorMessage == null)
        .map((record) => record.date.hour)
        .toList();
    if (syncHours.length >= 3) {
      final averageHour =
          syncHours.reduce((a, b) => a + b) ~/ syncHours.length;
      recommendations.add(
        SystemRecommendation(
          title: 'Ventana recomendada de backups',
          message:
              'Tus sincronizaciones exitosas suelen concentrarse alrededor de las ${averageHour.toString().padLeft(2, '0')}:00. Esa podría ser una buena franja para automatizar backups.',
          kind: SystemRecommendationKind.positive,
        ),
      );
    }

    if (activeAlerts.isEmpty && summary.errorSyncs == 0 && summary.totalSyncs > 0) {
      recommendations.add(
        const SystemRecommendation(
          title: 'Estado saludable',
          message:
              'No hay alertas activas y tus sincronizaciones recientes no muestran errores relevantes.',
          kind: SystemRecommendationKind.positive,
        ),
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        const SystemRecommendation(
          title: 'Seguir monitorizando',
          message:
              'Todavía no hay suficiente actividad para generar recomendaciones precisas. Continúa usando la app para mejorar la predicción.',
          kind: SystemRecommendationKind.warning,
        ),
      );
    }

    return recommendations;
  }
}




