import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_io/io.dart';

import '../../../domain/entities/ftp_profile.dart';
import '../../../domain/entities/remote_file.dart';
import '../../../domain/repositories/ftp_repository.dart';
import '../../../domain/repositories/monitoring_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/file_utils.dart';
import '../../viewmodels/browser_viewmodel.dart';
import '../history/history_screen.dart';
import '../sync/sync_screen.dart';

class RemoteBrowserScreen extends StatelessWidget {
  final FtpProfile profile;
  final FtpRepository repository;
  final MonitoringRepository monitoringRepository;
  final String ownerId;

  const RemoteBrowserScreen({
    super.key,
    required this.profile,
    required this.repository,
    required this.monitoringRepository,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BrowserViewModel(
        repository: repository,
        monitoringRepository: monitoringRepository,
        profile: profile,
        ownerId: ownerId,
      )..loadRemoteFiles(),
      child: _RemoteBrowserBody(
        profile: profile,
        repository: repository,
        monitoringRepository: monitoringRepository,
        ownerId: ownerId,
      ),
    );
  }
}

class _RemoteBrowserBody extends StatelessWidget {
  final FtpProfile profile;
  final FtpRepository repository;
  final MonitoringRepository monitoringRepository;
  final String ownerId;

  const _RemoteBrowserBody({
    required this.profile,
    required this.repository,
    required this.monitoringRepository,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BrowserViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile.name),
            Text(
              vm.currentRemotePath,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SyncScreen(
                  profile: profile,
                  repository: repository,
                  monitoringRepository: monitoringRepository,
                  ownerId: ownerId,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryScreen(
                  profile: profile,
                  repository: repository,
                  monitoringRepository: monitoringRepository,
                  ownerId: ownerId,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (kIsWeb)
            Container(
              width: double.infinity,
              color: AppTheme.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primary, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modo Demo: Las conexiones reales no son posibles en el navegador. Usa Android/Windows para archivos reales.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (vm.currentRemotePath != '/')
            _PathBar(path: vm.currentRemotePath, onGoUp: vm.goUpRemote),
          _FilterBar(vm: vm),
          if (vm.isTransferring)
            LinearProgressIndicator(
              value: vm.downloadProgress > 0 ? vm.downloadProgress : null,
              backgroundColor: AppTheme.surfaceVariant,
              color: AppTheme.primary,
            ),
          if (vm.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppTheme.error.withValues(alpha: 0.1),
              child: Text(
                vm.error!,
                style: const TextStyle(color: AppTheme.error),
              ),
            ),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.visibleRemoteFiles.isEmpty
                ? const Center(
                    child: Text(
                      'No hay resultados con los filtros actuales',
                      style: TextStyle(color: AppTheme.onSurfaceMuted),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => vm.loadRemoteFiles(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: vm.visibleRemoteFiles.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 56),
                      itemBuilder: (context, i) {
                        final file = vm.visibleRemoteFiles[i];
                        return _FileListTile(
                          file: file,
                          onTap: () async {
                            if (file.isDirectory) {
                              await vm.navigateRemote(file);
                            }
                          },
                          onDownload: file.isDirectory
                              ? null
                              : () => _download(context, vm, file),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _download(
    BuildContext context,
    BrowserViewModel vm,
    RemoteFile file,
  ) async {
    await vm.downloadFile(file);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vm.error == null
              ? '"${file.name}" descargado correctamente'
              : vm.error!,
        ),
        backgroundColor: vm.error == null ? AppTheme.success : AppTheme.error,
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final BrowserViewModel vm;
  const _FilterBar({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF30363D), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: vm.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppTheme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RemoteTypeFilter.values.map((filter) {
              final selected = vm.typeFilter == filter;
              final label = switch (filter) {
                RemoteTypeFilter.all => 'Todo',
                RemoteTypeFilter.folders => 'Carpetas',
                RemoteTypeFilter.images => 'Fotos',
                RemoteTypeFilter.videos => 'Vídeos',
                RemoteTypeFilter.documents => 'Documentos',
                RemoteTypeFilter.archives => 'Comprimidos',
                RemoteTypeFilter.others => 'Otros',
              };
              return FilterChip(
                selected: selected,
                label: Text(label),
                onSelected: (_) => vm.setTypeFilter(filter),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<RemoteSortField>(
                  initialValue: vm.sortField,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Ordenar por',
                    filled: true,
                    fillColor: AppTheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: RemoteSortField.name,
                      child: Text('Nombre'),
                    ),
                    DropdownMenuItem(
                      value: RemoteSortField.date,
                      child: Text('Fecha'),
                    ),
                    DropdownMenuItem(
                      value: RemoteSortField.size,
                      child: Text('Tamaño'),
                    ),
                    DropdownMenuItem(
                      value: RemoteSortField.type,
                      child: Text('Tipo'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) vm.setSortField(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: vm.toggleSortDirection,
                icon: Icon(
                  vm.sortDirection == SortDirection.asc
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                ),
                tooltip: vm.sortDirection == SortDirection.asc
                    ? 'Ascendente'
                    : 'Descendente',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${vm.visibleRemoteFiles.length} archivos visibles',
            style: const TextStyle(
              color: AppTheme.onSurfaceMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PathBar extends StatelessWidget {
  final String path;
  final VoidCallback onGoUp;
  const _PathBar({required this.path, required this.onGoUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 18),
            onPressed: onGoUp,
            tooltip: 'Subir nivel',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              path,
              style: const TextStyle(
                color: AppTheme.onSurfaceMuted,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FileListTile extends StatelessWidget {
  final RemoteFile file;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  const _FileListTile({
    required this.file,
    required this.onTap,
    this.onDownload,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BrowserViewModel>();
    final thumbnailPath = vm.thumbnails[file.path];

    Widget leading;
    if (!kIsWeb && thumbnailPath != null) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(thumbnailPath),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _defaultIcon(),
        ),
      );
    } else {
      leading = _defaultIcon();
    }

    return ListTile(
      leading: SizedBox(width: 40, height: 40, child: Center(child: leading)),
      title: Text(file.name),
      subtitle: file.isDirectory
          ? const Text('Carpeta')
          : Text(
              '${_formatSize(file.size)} • ${FileUtils.fileCategory(file.name)}'
              '${file.modifiedAt != null ? ' • ${vm.formatModifiedAt(file)}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
      trailing: onDownload != null
          ? IconButton(
              icon: const Icon(
                Icons.download_outlined,
                color: AppTheme.primary,
              ),
              onPressed: onDownload,
              tooltip: 'Descargar',
            )
          : const Icon(Icons.chevron_right, color: AppTheme.onSurfaceMuted),
      onTap: onTap,
    );
  }

  Widget _defaultIcon() {
    IconData iconData = Icons.insert_drive_file_outlined;
    Color iconColor = AppTheme.onSurfaceMuted;

    if (file.isDirectory) {
      iconData = Icons.folder;
      iconColor = const Color(0xFFE3B341);
    } else if (FileUtils.isVideo(file.name)) {
      iconData = Icons.videocam_outlined;
      iconColor = AppTheme.primary;
    } else if (FileUtils.isImage(file.name)) {
      iconData = Icons.image_outlined;
      iconColor = AppTheme.success;
    }

    return Icon(iconData, color: iconColor, size: 28);
  }
}
