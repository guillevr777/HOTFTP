import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/ftp_profile.dart';
import '../../../domain/entities/sync_record.dart';
import '../../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/sync_viewmodel.dart';

class HistoryScreen extends StatelessWidget {
  final FtpProfile profile;
  const HistoryScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SyncViewModel(
        repository: context.read<ProfileViewModel>().repository,
        profile: profile,
        ownerId: context.read<AuthViewModel>().currentUser?.uid ?? '',
      )..loadHistory(),
      child: const _HistoryBody(),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SyncViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de sincronizaciones')),
      body: vm.history.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppTheme.onSurfaceMuted),
                  SizedBox(height: 16),
                  Text(
                    'Sin datos disponibles',
                    style: TextStyle(color: AppTheme.onSurfaceMuted),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vm.history.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _HistoryCard(record: vm.history[i]),
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final SyncRecord record;
  const _HistoryCard({required this.record});

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasError = record.errorMessage != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasError ? Icons.error_outline : Icons.check_circle_outline,
                  color: hasError ? AppTheme.error : AppTheme.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _formatDate(record.date),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    record.mode,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.upload,
              label: 'Transferidos',
              value: '${record.filesTransferred}',
            ),
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.skip_next,
              label: 'Omitidos',
              value: '${record.filesSkipped}',
            ),
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.folder_outlined,
              label: 'Local',
              value: record.localPath,
            ),
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.cloud_outlined,
              label: 'Remota',
              value: record.remotePath,
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.onSurfaceMuted),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppTheme.onSurfaceMuted,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
