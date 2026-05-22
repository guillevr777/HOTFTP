import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/dump_transfer_service.dart';
import '../../../domain/entities/dump_schedule.dart';
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

  const SyncScreen({super.key, required this.profile, required this.ownerId});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final vm = SyncViewModel(
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
            );
            return vm;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final vm = DumpScheduleViewModel(
              getDumpScheduleForProfile: context
                  .read<IGetDumpScheduleForProfileUseCase>(),
              saveDumpSchedule: context.read<ISaveDumpScheduleUseCase>(),
              recordEvent: context.read<IRecordEventUseCase>(),
              profile: profile,
              ownerId: ownerId,
            );
            Future.microtask(vm.loadSchedule);
            return vm;
          },
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
                        hintText:
                            '/storage/emulated/0/DCIM o /storage/emulated/0/Download',
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
            _ScheduleEditor(scheduleVm: scheduleVm, syncVm: vm),
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
                      'Se omite si es igual; si cambia, se reemplaza',
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
          ],
        ),
      ),
    );
  }
}

class _ScheduleEditor extends StatelessWidget {
  final DumpScheduleViewModel scheduleVm;
  final SyncViewModel syncVm;

  const _ScheduleEditor({required this.scheduleVm, required this.syncVm});

  @override
  Widget build(BuildContext context) {
    final nextRun = scheduleVm.schedule?.nextRunAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  scheduleVm.enabled ? Icons.schedule : Icons.schedule_outlined,
                  color: scheduleVm.enabled
                      ? AppTheme.primary
                      : AppTheme.onSurfaceMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Activar / Desactivar programacion',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: scheduleVm.enabled,
                  onChanged: scheduleVm.isSaving ? null : scheduleVm.setEnabled,
                ),
              ],
            ),
            if (nextRun != null && scheduleVm.enabled) ...[
              const SizedBox(height: 4),
              Text(
                'Proxima ejecucion: ${_formatDateTime(nextRun)}',
                style: const TextStyle(color: AppTheme.onSurfaceMuted),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: scheduleVm.isSaving
                  ? null
                  : () => scheduleVm.copyFromManual(
                      manualLocalPath: syncVm.localPath,
                      manualRemotePath: syncVm.remotePath,
                      manualSourceSide: _sourceSideFor(syncVm.syncMode),
                      manualTransferMode: _transferModeFor(syncVm.syncMode),
                    ),
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Usar rutas y modo manual actuales'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: scheduleVm.localPath,
              onChanged: scheduleVm.setLocalPath,
              decoration: const InputDecoration(
                labelText: 'Ruta local programada',
                prefixIcon: Icon(Icons.phone_android),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: scheduleVm.remotePath,
              onChanged: scheduleVm.setRemotePath,
              decoration: const InputDecoration(
                labelText: 'Ruta remota programada',
                prefixIcon: Icon(Icons.cloud_outlined),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<DumpTransferMode>(
              segments: const [
                ButtonSegment(
                  value: DumpTransferMode.oneWay,
                  label: Text('Un sentido'),
                  icon: Icon(Icons.arrow_forward),
                ),
                ButtonSegment(
                  value: DumpTransferMode.syncBoth,
                  label: Text('Bidireccional'),
                  icon: Icon(Icons.sync_alt),
                ),
              ],
              selected: {scheduleVm.transferMode},
              onSelectionChanged: scheduleVm.isSaving
                  ? null
                  : (values) => scheduleVm.setTransferMode(values.first),
            ),
            const SizedBox(height: 12),
            if (scheduleVm.transferMode == DumpTransferMode.oneWay)
              SegmentedButton<DumpSourceSide>(
                segments: const [
                  ButtonSegment(
                    value: DumpSourceSide.local,
                    label: Text('Subir'),
                    icon: Icon(Icons.upload),
                  ),
                  ButtonSegment(
                    value: DumpSourceSide.remote,
                    label: Text('Bajar'),
                    icon: Icon(Icons.download),
                  ),
                ],
                selected: {scheduleVm.sourceSide},
                onSelectionChanged: scheduleVm.isSaving
                    ? null
                    : (values) => scheduleVm.setSourceSide(values.first),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: scheduleVm.intervalValue.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: scheduleVm.setIntervalValue,
                    decoration: const InputDecoration(
                      labelText: 'Cada',
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<DumpIntervalUnit>(
                  value: scheduleVm.intervalUnit,
                  items: const [
                    DropdownMenuItem(
                      value: DumpIntervalUnit.hours,
                      child: Text('horas'),
                    ),
                    DropdownMenuItem(
                      value: DumpIntervalUnit.days,
                      child: Text('dias'),
                    ),
                  ],
                  onChanged: scheduleVm.isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            scheduleVm.setIntervalUnit(value);
                          }
                        },
                ),
              ],
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: scheduleVm.deleteSourceAfterCopy,
              onChanged: scheduleVm.isSaving
                  ? null
                  : (value) =>
                        scheduleVm.setDeleteSourceAfterCopy(value ?? false),
              contentPadding: EdgeInsets.zero,
              title: const Text('Eliminar origen despues de copiar'),
              subtitle: const Text('Usalo solo si quieres mover archivos.'),
            ),
            if (scheduleVm.error != null) ...[
              const SizedBox(height: 8),
              Text(
                scheduleVm.error!,
                style: const TextStyle(color: AppTheme.error),
              ),
            ],
            if (scheduleVm.successMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                scheduleVm.successMessage!,
                style: const TextStyle(color: AppTheme.success),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: scheduleVm.isSaving ? null : scheduleVm.saveSchedule,
              icon: scheduleVm.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Guardar programacion'),
            ),
          ],
        ),
      ),
    );
  }

  static DumpSourceSide _sourceSideFor(SyncMode mode) {
    return mode == SyncMode.pull ? DumpSourceSide.remote : DumpSourceSide.local;
  }

  static DumpTransferMode _transferModeFor(SyncMode mode) {
    return mode == SyncMode.bidirectional
        ? DumpTransferMode.syncBoth
        : DumpTransferMode.oneWay;
  }

  static String _formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
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
                  onSelected: onChanged == null
                      ? null
                      : (_) => onChanged!(mode),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
