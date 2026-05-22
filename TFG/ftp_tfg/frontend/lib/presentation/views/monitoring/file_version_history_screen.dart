import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/file_version.dart';
import '../../../theme/app_theme.dart';
import '../../viewmodels/file_version_history_view_model.dart';
import '../../../domain/interfaces/i_get_file_version_history_use_case.dart';

class FileVersionHistoryScreen extends StatelessWidget {
  final String ownerId;
  final int profileId;
  final String filePath;
  final String fileName;

  const FileVersionHistoryScreen({
    super.key,
    required this.ownerId,
    required this.profileId,
    required this.filePath,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FileVersionHistoryViewModel(
        getFileVersionHistory: context.read<IGetFileVersionHistoryUseCase>(),
        ownerId: ownerId,
        profileId: profileId,
        filePath: filePath,
      )..load(),
      child: const _FileVersionHistoryBody(),
    );
  }
}

class _FileVersionHistoryBody extends StatelessWidget {
  const _FileVersionHistoryBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FileVersionHistoryViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de versiones'),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: vm.load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Archivo monitorizado',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            vm.filePath,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Versiones registradas: ${vm.versions.length}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (vm.error != null) ...[
                    Card(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(vm.error!),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (vm.versions.isEmpty)
                    const _EmptyState(text: 'No hay versiones para este archivo')
                  else
                    ...vm.versions.map(
                      (version) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _VersionDetailCard(
                          version: version,
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

class _VersionDetailCard extends StatelessWidget {
  final FileVersion version;
  final String Function(DateTime?) formatDateTime;

  const _VersionDetailCard({
    required this.version,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restore_rounded, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Versión ${version.versionNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Origen: ${version.source}',
              style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'Tamaño: ${version.size} bytes',
              style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'Modificado: ${formatDateTime(version.modifiedAt)}',
              style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'Registrado: ${formatDateTime(version.createdAt)}',
              style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted),
            ),
          ],
        ),
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




