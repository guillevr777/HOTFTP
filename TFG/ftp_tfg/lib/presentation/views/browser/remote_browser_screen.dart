import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/ftp_profile.dart';
import '../../../domain/entities/local_file.dart';
import '../../../domain/entities/remote_file.dart';
import '../../../domain/interfaces/i_download_file_use_case.dart';
import '../../../domain/interfaces/i_download_thumbnail_use_case.dart';
import '../../../domain/interfaces/i_get_latest_file_version_use_case.dart';
import '../../../domain/interfaces/i_get_local_file_details_use_case.dart';
import '../../../domain/interfaces/i_get_local_files_use_case.dart';
import '../../../domain/interfaces/i_get_remote_files_use_case.dart';
import '../../../domain/interfaces/i_record_file_version_use_case.dart';
import '../../../domain/interfaces/i_upload_file_use_case.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/file_utils.dart';
import '../../viewmodels/browser_view_model.dart';
import '../history/history_screen.dart';
import '../sync/sync_screen.dart';
import 'browser_file_grid_tile.dart';
import 'browser_file_preview_screen.dart';
import 'local_browser_file_grid_tile.dart';
import 'local_browser_file_preview_screen.dart';

class RemoteBrowserScreen extends StatelessWidget {
  final FtpProfile profile;
  final String ownerId;

  const RemoteBrowserScreen({
    super.key,
    required this.profile,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BrowserViewModel(
        getRemoteFiles: context.read<IGetRemoteFilesUseCase>(),
        getLocalFiles: context.read<IGetLocalFilesUseCase>(),
        getLocalFileDetails: context.read<IGetLocalFileDetailsUseCase>(),
        downloadFileUseCase: context.read<IDownloadFileUseCase>(),
        uploadFileUseCase: context.read<IUploadFileUseCase>(),
        downloadThumbnailUseCase: context.read<IDownloadThumbnailUseCase>(),
        getLatestFileVersion: context.read<IGetLatestFileVersionUseCase>(),
        recordFileVersion: context.read<IRecordFileVersionUseCase>(),
        profile: profile,
        ownerId: ownerId,
      )
        ..resetFilters()
        ..loadRemoteFiles(),
      child: _RemoteBrowserBody(profile: profile, ownerId: ownerId),
    );
  }
}

class _RemoteBrowserBody extends StatefulWidget {
  final FtpProfile profile;
  final String ownerId;

  const _RemoteBrowserBody({required this.profile, required this.ownerId});

  @override
  State<_RemoteBrowserBody> createState() => _RemoteBrowserBodyState();
}

class _RemoteBrowserBodyState extends State<_RemoteBrowserBody> {
  final ScrollController _scrollController = ScrollController();
  String _lastListSignature = '';
  String _lastPrioritySignature = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final vm = context.read<BrowserViewModel>();
    final hasMore = vm.isLocalDestination
        ? vm.hasMoreLocalFiles
        : vm.hasMoreRemoteFiles;
    if (!hasMore) return;
    if (_scrollController.position.extentAfter < 600) {
      if (vm.isLocalDestination) {
        vm.loadMoreVisibleLocalFiles();
      } else {
        vm.loadMoreVisibleRemoteFiles();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BrowserViewModel>();
    final displayedFiles = vm.isLocalDestination
        ? vm.displayedLocalFiles
        : vm.displayedRemoteFiles;
    final listSignature =
        '${vm.currentPath}|${vm.searchQuery}|${vm.sortField.name}|${vm.sortDirection.name}|${vm.typeFilter.name}|${vm.destination.name}';
    if (_lastListSignature != listSignature) {
      _lastListSignature = listSignature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(0);
      });
    }

    if (vm.isRemoteDestination) {
      final prioritySignature = [
        vm.currentRemotePath,
        vm.displayedRemoteFiles.take(12).map((file) => file.path).join('|'),
      ].join('::');
      if (_lastPrioritySignature != prioritySignature) {
        _lastPrioritySignature = prioritySignature;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<BrowserViewModel>().prioritizeVisibleThumbnails(
                vm.displayedRemoteFiles,
                vm.currentRemotePath,
              );
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.profile.name),
            Text(
              vm.currentPath,
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
                  profile: widget.profile,
                  ownerId: widget.ownerId,
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
                  profile: widget.profile,
                  ownerId: widget.ownerId,
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
          _DestinationBar(vm: vm),
          if (vm.currentPath != '/')
            _PathBar(
              path: vm.currentPath,
              onGoUp: vm.isLocalDestination ? vm.goUpLocal : vm.goUpRemote,
            ),
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
                : vm.isRemoteDestination
                    ? _buildRemoteContent(context, vm, displayedFiles.cast<RemoteFile>())
                    : _buildLocalContent(context, vm, displayedFiles.cast<LocalFile>()),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteContent(
    BuildContext context,
    BrowserViewModel vm,
    List<RemoteFile> displayedFiles,
  ) {
    if (vm.error != null && vm.remoteFiles.isEmpty) {
      return _EmptyErrorState(
        message: vm.error!,
        onRetry: () => vm.loadRemoteFiles(forceRefresh: true),
      );
    }
    if (vm.remoteFiles.isEmpty) {
      return const Center(
        child: Text(
          'No hay archivos en esta carpeta',
          style: TextStyle(color: AppTheme.onSurfaceMuted),
        ),
      );
    }
    if (vm.visibleRemoteFiles.isEmpty) {
      return Center(
        child: Text(
          vm.searchQuery.isNotEmpty || vm.typeFilter != RemoteTypeFilter.all
              ? 'No hay resultados con los filtros actuales'
              : 'No hay archivos visibles',
          style: const TextStyle(color: AppTheme.onSurfaceMuted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadRemoteFiles(forceRefresh: true),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        cacheExtent: 0,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.9,
        ),
        itemCount: displayedFiles.length + (vm.hasMoreRemoteFiles ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= displayedFiles.length) {
            return const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final file = displayedFiles[i];
          return BrowserFileGridTile(
            key: ValueKey(file.path),
            file: file,
            remotePath: vm.currentRemotePath,
            onTap: () async {
              if (file.isDirectory) {
                await vm.navigateRemote(file);
                return;
              }
              if (!context.mounted) return;
              await _openPreview(context, vm, file);
            },
            onDownload: file.isDirectory ? null : () => _download(context, vm, file),
          );
        },
      ),
    );
  }

  Widget _buildLocalContent(
    BuildContext context,
    BrowserViewModel vm,
    List<LocalFile> displayedFiles,
  ) {
    if (vm.error != null && vm.localFiles.isEmpty) {
      return _EmptyErrorState(
        message: vm.error!,
        onRetry: () => vm.loadLocalFiles(forceRefresh: true),
      );
    }
    if (vm.localFiles.isEmpty) {
      return const Center(
        child: Text(
          'No hay archivos en esta carpeta local',
          style: TextStyle(color: AppTheme.onSurfaceMuted),
        ),
      );
    }
    if (vm.visibleLocalFiles.isEmpty) {
      return Center(
        child: Text(
          vm.searchQuery.isNotEmpty || vm.typeFilter != RemoteTypeFilter.all
              ? 'No hay resultados con los filtros actuales'
              : 'No hay archivos visibles',
          style: const TextStyle(color: AppTheme.onSurfaceMuted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadLocalFiles(forceRefresh: true),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        cacheExtent: 0,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.9,
        ),
        itemCount: displayedFiles.length + (vm.hasMoreLocalFiles ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= displayedFiles.length) {
            return const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final file = displayedFiles[i];
          return LocalBrowserFileGridTile(
            key: ValueKey(file.path),
            file: file,
            onTap: () async {
              if (file.isDirectory) {
                await vm.navigateLocal(file);
                return;
              }
              if (!context.mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LocalBrowserFilePreviewScreen(
          file: file,
          onRepairRequested: (localFile) => vm.repairLocalFile(localFile),
        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showLocalDetails(BuildContext context, LocalFile file) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.background,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(file.name, style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 16),
                _DetailRow(
                  label: 'Nombre',
                  value: file.name,
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Tipo',
                  value: FileUtils.fileCategory(
                    file.name,
                    isDirectory: file.isDirectory,
                  ),
                  icon: Icons.category_outlined,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Tamano',
                  value: file.isDirectory ? 'Carpeta' : FileUtils.formatBytes(file.size),
                  icon: Icons.sd_storage_outlined,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Fecha',
                  value: file.lastModified == null
                      ? 'Sin fecha'
                      : '${file.lastModified!.day.toString().padLeft(2, '0')}/${file.lastModified!.month.toString().padLeft(2, '0')}/${file.lastModified!.year} ${file.lastModified!.hour.toString().padLeft(2, '0')}:${file.lastModified!.minute.toString().padLeft(2, '0')}',
                  icon: Icons.schedule_outlined,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Ruta',
                  value: file.path,
                  icon: Icons.route_outlined,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPreview(
    BuildContext context,
    BrowserViewModel vm,
    RemoteFile file,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BrowserFilePreviewScreen(
          file: file,
          onDownload: (onProgress) => vm.downloadFile(
            file,
            onProgress: onProgress,
          ),
          profile: vm.profile,
          downloadFileUseCase: context.read<IDownloadFileUseCase>(),
        ),
      ),
    );
  }

  Future<void> _download(
    BuildContext context,
    BrowserViewModel vm,
    RemoteFile file,
  ) async {
    await vm.downloadFile(file);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vm.error == null ? '"${file.name}" descargado correctamente' : vm.error!,
        ),
        backgroundColor: vm.error == null ? AppTheme.success : AppTheme.error,
      ),
    );
  }
}

class _DestinationBar extends StatelessWidget {
  final BrowserViewModel vm;

  const _DestinationBar({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            selected: vm.isRemoteDestination,
            label: const Text('Remoto'),
            onSelected: (_) => vm.setDestination(BrowserDestination.remote),
          ),
          ChoiceChip(
            selected: vm.isLocalDestination,
            label: const Text('Local'),
            onSelected: (_) => vm.setDestination(BrowserDestination.local),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppTheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 15, height: 1.25)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EmptyErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: AppTheme.onSurfaceMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No se pudo cargar la carpeta',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceMuted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
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
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: vm.toggleSortDirection,
                icon: Icon(
                  vm.sortDirection == SortDirection.asc
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                ),
                label: Text(
                  switch (vm.sortField) {
                    RemoteSortField.name => 'Nombre',
                    RemoteSortField.date => 'Fecha',
                    RemoteSortField.size => 'Tamano',
                    RemoteSortField.type => 'Tipo',
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<RemoteSortField>(
                value: vm.sortField,
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
                    child: Text('Tamano'),
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
            ],
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
                RemoteTypeFilter.videos => 'Videos',
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(onPressed: onGoUp, icon: const Icon(Icons.arrow_upward)),
          Expanded(child: Text(path)),
        ],
      ),
    );
  }
}



