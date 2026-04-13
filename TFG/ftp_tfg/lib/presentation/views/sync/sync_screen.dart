import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/ftp_profile.dart';
import '../../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/sync_viewmodel.dart';

class SyncScreen extends StatelessWidget {
  final FtpProfile profile;
  const SyncScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SyncViewModel(
        repository: context.read<ProfileViewModel>().repository,
        profile: profile,
        ownerId: context.read<AuthViewModel>().currentUser?.uid ?? '',
      ),
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
              'RUTAS',
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
                  children: [
                    _PathRow(
                      label: 'Local',
                      path: vm.localPath,
                      icon: Icons.phone_android,
                    ),
                    const Divider(height: 24),
                    _PathRow(
                      label: 'Remota',
                      path: vm.remotePath,
                      icon: Icons.cloud_outlined,
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

class _PathRow extends StatelessWidget {
  final String label;
  final String path;
  final IconData icon;
  const _PathRow({
    required this.label,
    required this.path,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.onSurfaceMuted, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.onSurfaceMuted,
                fontSize: 12,
              ),
            ),
            Text(path, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
