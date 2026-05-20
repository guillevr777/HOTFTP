import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/dump_transfer_service.dart';
import '../../../domain/entities/ftp_profile.dart';
import '../../../theme/app_theme.dart';
import '../../viewmodels/dump_schedule_view_model.dart';
import '../../viewmodels/sync_view_model.dart';
import '../../../domain/interfaces/i_create_alert_use_case.dart';
import '../../../domain/interfaces/i_detect_conflicts_use_case.dart';
import '../../../domain/interfaces/i_evaluate_sync_rules_use_case.dart';
import '../../../domain/interfaces/i_get_active_alerts_use_case.dart';
import '../../../domain/interfaces/i_get_dump_schedule_for_profile_use_case.dart';
import '../../../domain/interfaces/i_get_sync_history_use_case.dart';
import '../../../domain/interfaces/i_record_event_use_case.dart';
import '../../../domain/interfaces/i_save_dump_schedule_use_case.dart';
import '../../../domain/interfaces/i_save_sync_record_use_case.dart';

class SyncScreen extends StatelessWidget {
  final FtpProfile profile;
  final String ownerId;

  const SyncScreen({
    super.key,
    required this.profile,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SyncViewModel(
            detectConflicts: context.read<IDetectConflictsUseCase>(),
            saveSyncRecord: context.read<ISaveSyncRecordUseCase>(),
            getSyncHistory: context.read<IGetSyncHistoryUseCase>(),
            getActiveAlerts: context.read<IGetActiveAlertsUseCase>(),
            evaluateSyncRules: context.read<IEvaluateSyncRulesUseCase>(),
            recordEvent: context.read<IRecordEventUseCase>(),
            createAlert: context.read<ICreateAlertUseCase>(),
            profile: profile,
            ownerId: ownerId,
            transferService: context.read<DumpTransferService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => DumpScheduleViewModel(
            getDumpScheduleForProfile:
                context.read<IGetDumpScheduleForProfileUseCase>(),
            saveDumpSchedule: context.read<ISaveDumpScheduleUseCase>(),
            profile: profile,
            ownerId: ownerId,
          )..loadSchedule(),
        ),
      ],
      child: _SyncBody(profile: profile),
    );
  }
}

class _SyncBody extends StatelessWidget {
  final FtpProfile profile;
  const _SyncBody({required this.profile});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SyncViewModel>();
    final scheduleVm = context.watch<DumpScheduleViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sincronizacion')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.dns, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          profile.host,
                          style: const TextStyle(
                            color: AppTheme.onSurfaceMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'MODO DE SINCRONIZACION',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _ModeSelector(
              selected: vm.syncMode,
              onChanged: vm.isSyncing ? null : vm.setSyncMode,
            ),
            const SizedBox(height: 20),
            const Text(
              'RUTAS MANUALES',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: vm.localPath,
                      onChanged: vm.setLocalPath,
                      decoration: const InputDecoration(
                        labelText: 'Ruta local',
                        hintText: '/storage/emulated/0/DCIM/Camera',
                        prefixIcon: Icon(Icons.phone_android),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: vm.remotePath,
                      onChanged: vm.setRemotePath,
                      decoration: const InputDecoration(
                        labelText: 'Ruta remota',
                        hintText: '/',
                        prefixIcon: Icon(Icons.cloud_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (vm.isSyncing) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: vm.syncProgress == 0 ? null : vm.syncProgress,
                  minHeight: 10,
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                vm.syncStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.onSurfaceMuted),
              ),
              if (vm.currentItemPath != null) ...[
                const SizedBox(height: 4),
                Text(
                  vm.currentItemPath!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                vm.syncSummaryText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (vm.isDone && !vm.isSyncing) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.success,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sincronizacion completada',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vm.filesTransferred} archivos transferidos, ${vm.directoriesCreated} carpetas creadas, ${vm.filesSkipped} omitidos',
                      style: const TextStyle(
                        color: AppTheme.onSurfaceMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (vm.error != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  vm.error!,
                  style: const TextStyle(color: AppTheme.error),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (vm.conflicts.isNotEmpty && !vm.isSyncing) ...[
              const Text(
                'CONFLICTOS DETECTADOS',
                style: TextStyle(
                  color: AppTheme.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              ...vm.conflicts.map(
                (c) => Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.warning_amber,
                      color: Colors.orange,
                    ),
                    title: Text(c.fileName),
                    subtitle: const Text(
                      'Existe en local y remoto',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: vm.isSyncing ? null : vm.startSync,
              icon: vm.isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.sync),
              label: const Text('Iniciar sincronizacion'),
            ),
            const SizedBox(height: 12),
            if (scheduleVm.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (scheduleVm.schedule != null)
              Card(
                child: ListTile(
                  leading: Icon(
                    scheduleVm.enabled
                        ? Icons.schedule
                        : Icons.schedule_outlined,
                    color: scheduleVm.enabled
                        ? AppTheme.primary
                        : AppTheme.onSurfaceMuted,
                  ),
                  title: Text(
                    scheduleVm.enabled
                        ? 'Volcado recurrente activo'
                        : 'Volcado recurrente desactivado',
                  ),
                  subtitle: Text(
                    scheduleVm.enabled
                        ? 'PrÃ³xima ejecuciÃ³n: ${scheduleVm.schedule!.nextRunAt ?? 'Sin fecha'}'
                        : 'Guarda la programaciÃ³n para activarlo',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final SyncMode selected;
  final ValueChanged<SyncMode>? onChanged;

  const _ModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: SyncMode.values
          .map(
            (mode) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(mode.name),
                  selected: selected == mode,
                  onSelected: onChanged == null ? null : (_) => onChanged!(mode),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}




