import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/dump_schedule.dart';
import '../../../domain/entities/ftp_profile.dart';
import '../../../domain/repositories/ftp_repository.dart';
import '../../../domain/repositories/monitoring_repository.dart';
import '../../../theme/app_theme.dart';
import '../../viewmodels/dump_schedule_viewmodel.dart';
import '../../viewmodels/sync_viewmodel.dart';

class SyncScreen extends StatelessWidget {
  final FtpProfile profile;
  final FtpRepository repository;
  final MonitoringRepository monitoringRepository;
  final String ownerId;

  const SyncScreen({
    super.key,
    required this.profile,
    required this.repository,
    required this.monitoringRepository,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SyncViewModel(
            repository: repository,
            monitoringRepository: monitoringRepository,
            profile: profile,
            ownerId: ownerId,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DumpScheduleViewModel(
            repository: repository,
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
              const LinearProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 12),
              const Text(
                'Sincronizando...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.onSurfaceMuted),
              ),
              const SizedBox(height: 8),
              Text(
                'Transferidos: ${vm.filesTransferred}  |  Omitidos: ${vm.filesSkipped}',
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
                      '${vm.filesTransferred} archivos transferidos, ${vm.filesSkipped} omitidos',
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
              label: Text(
                vm.isSyncing ? 'Sincronizando...' : 'Iniciar sincronizacion',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'VOLUMEN RECURRENTE',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            if (scheduleVm.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              const _ScheduleEditor(),
          ],
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final SyncMode selected;
  final void Function(SyncMode)? onChanged;
  const _ModeSelector({required this.selected, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: SyncMode.values.map((mode) {
        final isSelected = mode == selected;
        final label = switch (mode) {
          SyncMode.push => 'Push',
          SyncMode.pull => 'Pull',
          SyncMode.bidirectional => 'Bidireccional',
        };
        final icon = switch (mode) {
          SyncMode.push => Icons.upload,
          SyncMode.pull => Icons.download,
          SyncMode.bidirectional => Icons.sync_alt,
        };
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.15)
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : const Color(0xFF30363D),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.onSurfaceMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.onSurfaceMuted,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}


class _ScheduleEditor extends StatefulWidget {
  const _ScheduleEditor();

  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  final TextEditingController _localController = TextEditingController();
  final TextEditingController _remoteController = TextEditingController();
  final TextEditingController _intervalController = TextEditingController();
  DumpScheduleViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<DumpScheduleViewModel>();
    if (_vm != vm) {
      _vm?.removeListener(_syncControllers);
      _vm = vm;
      _vm!.addListener(_syncControllers);
      _syncControllers();
    }
  }

  void _syncControllers() {
    final vm = context.read<DumpScheduleViewModel>();
    if (_localController.text != vm.localPath) {
      _localController.text = vm.localPath;
    }
    if (_remoteController.text != vm.remotePath) {
      _remoteController.text = vm.remotePath;
    }
    final intervalText = vm.intervalValue.toString();
    if (_intervalController.text != intervalText) {
      _intervalController.text = intervalText;
    }
  }

  @override
  void dispose() {
    _vm?.removeListener(_syncControllers);
    _localController.dispose();
    _remoteController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleVm = context.watch<DumpScheduleViewModel>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: scheduleVm.enabled,
              onChanged: scheduleVm.setEnabled,
              title: const Text('Activar volcado recurrente'),
              subtitle: const Text(
                'Se ejecuta de forma periódica mientras la app esté activa.',
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _localController,
              onChanged: scheduleVm.setLocalPath,
              decoration: const InputDecoration(
                labelText: 'Ruta local de origen/destino',
                hintText: '/storage/emulated/0/Download',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remoteController,
              onChanged: scheduleVm.setRemotePath,
              decoration: const InputDecoration(
                labelText: 'Ruta remota de origen/destino',
                hintText: '/',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DumpTransferMode>(
              initialValue: scheduleVm.transferMode,
              decoration: const InputDecoration(
                labelText: 'Tipo de volcado',
              ),
              items: const [
                DropdownMenuItem(
                  value: DumpTransferMode.oneWay,
                  child: Text('De un sitio a otro'),
                ),
                DropdownMenuItem(
                  value: DumpTransferMode.syncBoth,
                  child: Text('Sincronizar ambos lados'),
                ),
              ],
              onChanged: (value) {
                if (value != null) scheduleVm.setTransferMode(value);
              },
            ),
            const SizedBox(height: 12),
            if (scheduleVm.transferMode == DumpTransferMode.oneWay) ...[
              DropdownButtonFormField<DumpSourceSide>(
                initialValue: scheduleVm.sourceSide,
                decoration: const InputDecoration(
                  labelText: 'Origen',
                ),
                items: const [
                  DropdownMenuItem(
                    value: DumpSourceSide.local,
                    child: Text('Local'),
                  ),
                  DropdownMenuItem(
                    value: DumpSourceSide.remote,
                    child: Text('Remoto'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) scheduleVm.setSourceSide(value);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: scheduleVm.deleteSourceAfterCopy,
                onChanged: scheduleVm.setDeleteSourceAfterCopy,
                title: const Text('Eliminar del origen tras copiar'),
                subtitle: const Text(
                  'Si se desactiva, el origen se conserva.',
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    onChanged: scheduleVm.setIntervalValue,
                    decoration: const InputDecoration(
                      labelText: 'Cada',
                      helperText: 'Número de horas o días',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<DumpIntervalUnit>(
                    initialValue: scheduleVm.intervalUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unidad',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: DumpIntervalUnit.hours,
                        child: Text('Horas'),
                      ),
                      DropdownMenuItem(
                        value: DumpIntervalUnit.days,
                        child: Text('Días'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) scheduleVm.setIntervalUnit(value);
                    },
                  ),
                ),
              ],
            ),
            if (scheduleVm.schedule?.nextRunAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Próxima ejecución: ${scheduleVm.schedule!.nextRunAt}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
            ],
            if (scheduleVm.error != null) ...[
              const SizedBox(height: 12),
              Text(
                scheduleVm.error!,
                style: const TextStyle(color: AppTheme.error),
              ),
            ],
            if (scheduleVm.successMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                scheduleVm.successMessage!,
                style: const TextStyle(color: AppTheme.success),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: scheduleVm.isSaving
                  ? null
                  : () => scheduleVm.saveSchedule(),
              icon: scheduleVm.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.schedule),
              label: Text(
                scheduleVm.isSaving
                    ? 'Guardando...'
                    : 'Guardar volcado recurrente',
              ),
            ),
          ],
        ),
      ),
    );
  }
}


