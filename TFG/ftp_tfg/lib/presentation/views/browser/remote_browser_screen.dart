import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_io/io.dart';

import '../../../domain/entities/ftp_profile.dart';
import '../../../domain/entities/remote_file.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/file_utils.dart';
import '../../viewmodels/browser_view_model.dart';
import '../history/history_screen.dart';
import '../sync/sync_screen.dart';
import '../../../domain/interfaces/i_download_file_use_case.dart';
import '../../../domain/interfaces/i_download_thumbnail_use_case.dart';
import '../../../domain/interfaces/i_get_latest_file_version_use_case.dart';
import '../../../domain/interfaces/i_get_local_files_use_case.dart';
import '../../../domain/interfaces/i_get_remote_files_use_case.dart';
import '../../../domain/interfaces/i_record_file_version_use_case.dart';
import '../../../domain/interfaces/i_upload_file_use_case.dart';

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
      create: (context) =>
          BrowserViewModel(
              getRemoteFiles: context.read<IGetRemoteFilesUseCase>(),
              getLocalFiles: context.read<IGetLocalFilesUseCase>(),
              downloadFileUseCase: context.read<IDownloadFileUseCase>(),
              uploadFileUseCase: context.read<IUploadFileUseCase>(),
              downloadThumbnailUseCase: context
                  .read<IDownloadThumbnailUseCase>(),
              getLatestFileVersion: context
                  .read<IGetLatestFileVersionUseCase>(),
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
    if (!vm.hasMoreRemoteFiles) return;
    if (_scrollController.position.extentAfter < 600) {
      vm.loadMoreVisibleRemoteFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BrowserViewModel>();
    final displayedFiles = vm.displayedRemoteFiles;
    final listSignature =
        '${vm.currentRemotePath}|${vm.searchQuery}|${vm.sortField.name}|${vm.sortDirection.name}|${vm.typeFilter.name}|${vm.displayMode.name}|${vm.gridDensity.name}';
    if (_lastListSignature != listSignature) {
      _lastListSignature = listSignature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(0);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.profile.name),
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
                : vm.error != null && vm.remoteFiles.isEmpty
                ? _EmptyErrorState(
                    message: vm.error!,
                    onRetry: () => vm.loadRemoteFiles(forceRefresh: true),
                  )
                : vm.remoteFiles.isEmpty
                ? const Center(
                    child: Text(
                      'No hay archivos en esta carpeta',
                      style: TextStyle(color: AppTheme.onSurfaceMuted),
                    ),
                  )
                : vm.visibleRemoteFiles.isEmpty
                ? Center(
                    child: Text(
                      vm.searchQuery.isNotEmpty ||
                              vm.typeFilter != RemoteTypeFilter.all
                          ? 'No hay resultados con los filtros actuales'
                          : 'No hay archivos visibles',
                      style: const TextStyle(color: AppTheme.onSurfaceMuted),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => vm.loadRemoteFiles(forceRefresh: true),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (vm.displayMode == RemoteFileViewMode.grid) {
                          return GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            cacheExtent: 0,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _gridCrossAxisCount(
                                    constraints.maxWidth,
                                    vm.gridDensity,
                                  ),
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: _gridChildAspectRatio(
                                    vm.gridDensity,
                                  ),
                                ),
                            itemCount:
                                displayedFiles.length +
                                (vm.hasMoreRemoteFiles ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i >= displayedFiles.length) {
                                return const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              final file = displayedFiles[i];
                              return _FileGridTile(
                                key: ValueKey(file.path),
                                file: file,
                                remotePath: vm.currentRemotePath,
                                density: vm.gridDensity,
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
                          );
                        }

                        return ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          cacheExtent: 0,
                          itemCount:
                              displayedFiles.length +
                              (vm.hasMoreRemoteFiles ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, indent: 56),
                          itemBuilder: (context, i) {
                            if (i >= displayedFiles.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final file = displayedFiles[i];
                            return _FileListTile(
                              key: ValueKey(file.path),
                              file: file,
                              remotePath: vm.currentRemotePath,
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
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final searchField = TextField(
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
              );

              final viewToggle = ToggleButtons(
                isSelected: [
                  vm.displayMode == RemoteFileViewMode.list,
                  vm.displayMode == RemoteFileViewMode.grid,
                ],
                onPressed: (index) {
                  vm.setDisplayMode(
                    index == 0
                        ? RemoteFileViewMode.list
                        : RemoteFileViewMode.grid,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
                children: const [
                  Tooltip(
                    message: 'Vista de lista',
                    child: Icon(Icons.view_agenda_outlined),
                  ),
                  Tooltip(
                    message: 'Vista en rejilla',
                    child: Icon(Icons.grid_view_outlined),
                  ),
                ],
              );

              final densityToggle = ToggleButtons(
                isSelected: [
                  vm.gridDensity == RemoteGridDensity.compact,
                  vm.gridDensity == RemoteGridDensity.medium,
                  vm.gridDensity == RemoteGridDensity.large,
                ],
                onPressed: (index) {
                  vm.setGridDensity(switch (index) {
                    0 => RemoteGridDensity.compact,
                    1 => RemoteGridDensity.medium,
                    _ => RemoteGridDensity.large,
                  });
                },
                borderRadius: BorderRadius.circular(12),
                constraints: const BoxConstraints(minHeight: 44, minWidth: 52),
                children: const [
                  Tooltip(message: 'Tarjetas compactas', child: Text('S')),
                  Tooltip(message: 'Tarjetas medias', child: Text('M')),
                  Tooltip(message: 'Tarjetas grandes', child: Text('L')),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [viewToggle, densityToggle],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 12),
                  viewToggle,
                  const SizedBox(width: 12),
                  densityToggle,
                ],
              );
            },
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

int _gridCrossAxisCount(double width, RemoteGridDensity density) {
  final targetWidth = switch (density) {
    RemoteGridDensity.compact => 180.0,
    RemoteGridDensity.medium => 220.0,
    RemoteGridDensity.large => 280.0,
  };
  final count = (width / targetWidth).floor();
  return count.clamp(2, 6);
}

double _gridChildAspectRatio(RemoteGridDensity density) {
  return switch (density) {
    RemoteGridDensity.compact => 0.95,
    RemoteGridDensity.medium => 0.88,
    RemoteGridDensity.large => 0.8,
  };
}

class _FileGridTile extends StatelessWidget {
  final RemoteFile file;
  final String remotePath;
  final RemoteGridDensity density;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  const _FileGridTile({
    super.key,
    required this.file,
    required this.remotePath,
    required this.density,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceVariant.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _GridPreview(file: file, remotePath: remotePath),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                file.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                file.isDirectory ? 'Carpeta' : '${file.size} bytes',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
              if (onDownload != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.download),
                    onPressed: onDownload,
                    tooltip: 'Descargar',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPreview extends StatefulWidget {
  final RemoteFile file;
  final String remotePath;

  const _GridPreview({required this.file, required this.remotePath});

  @override
  State<_GridPreview> createState() => _GridPreviewState();
}

class _GridPreviewState extends State<_GridPreview> {
  String? _requestedPath;

  @override
  void didUpdateWidget(covariant _GridPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _requestedPath = null;
    }
  }

  void _scheduleThumbnailRequest() {
    if (_requestedPath == widget.file.path) return;
    _requestedPath = widget.file.path;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BrowserViewModel>().requestThumbnail(
        widget.file,
        widget.remotePath,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BrowserViewModel>();
    final thumbPath = vm.thumbnails[widget.file.path];

    if (widget.file.isDirectory) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withValues(alpha: 0.15),
              AppTheme.surfaceVariant.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.folder, size: 52),
      );
    }

    if (thumbPath == null) {
      if (FileUtils.isImage(widget.file.name) ||
          FileUtils.isVideo(widget.file.name)) {
        _scheduleThumbnailRequest();
      }
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          FileUtils.isVideo(widget.file.name)
              ? Icons.videocam_outlined
              : FileUtils.isImage(widget.file.name)
              ? Icons.image_outlined
              : Icons.insert_drive_file,
          size: 44,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(
        File(thumbPath),
        fit: BoxFit.cover,
        cacheWidth: 256,
        cacheHeight: 256,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.broken_image_outlined, size: 44),
        ),
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

class _FileListTile extends StatelessWidget {
  final RemoteFile file;
  final String remotePath;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  const _FileListTile({
    super.key,
    required this.file,
    required this.remotePath,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: file.isDirectory
          ? const Icon(Icons.folder)
          : _FileLeading(file: file, remotePath: remotePath),
      title: Text(file.name),
      onTap: onTap,
      trailing: onDownload == null
          ? null
          : IconButton(icon: const Icon(Icons.download), onPressed: onDownload),
    );
  }
}

class _FileLeading extends StatefulWidget {
  final RemoteFile file;
  final String remotePath;

  const _FileLeading({required this.file, required this.remotePath});

  @override
  State<_FileLeading> createState() => _FileLeadingState();
}

class _FileLeadingState extends State<_FileLeading> {
  String? _requestedPath;

  @override
  void didUpdateWidget(covariant _FileLeading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _requestedPath = null;
    }
  }

  void _scheduleThumbnailRequest() {
    if (_requestedPath == widget.file.path) return;
    _requestedPath = widget.file.path;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BrowserViewModel>().requestThumbnail(
        widget.file,
        widget.remotePath,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BrowserViewModel>();
    final thumbPath = vm.thumbnails[widget.file.path];

    if (thumbPath == null) {
      if (FileUtils.isImage(widget.file.name) ||
          FileUtils.isVideo(widget.file.name)) {
        _scheduleThumbnailRequest();
      }
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.surfaceVariant.withValues(alpha: 0.95),
              AppTheme.surfaceVariant.withValues(alpha: 0.65),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          FileUtils.isVideo(widget.file.name)
              ? Icons.videocam_outlined
              : FileUtils.isImage(widget.file.name)
              ? Icons.image_outlined
              : Icons.insert_drive_file,
          size: 22,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(thumbPath),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        cacheWidth: 96,
        cacheHeight: 96,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 48,
          height: 48,
          color: AppTheme.surfaceVariant,
          child: const Icon(Icons.broken_image_outlined, size: 22),
        ),
      ),
    );
  }
}
