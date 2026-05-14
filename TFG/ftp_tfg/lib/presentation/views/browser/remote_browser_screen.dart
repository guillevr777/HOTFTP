import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
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
        '${vm.currentRemotePath}|${vm.searchQuery}|${vm.sortField.name}|${vm.sortDirection.name}|${vm.typeFilter.name}';
    if (_lastListSignature != listSignature) {
      _lastListSignature = listSignature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(0);
      });
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
                      itemCount:
                          displayedFiles.length + (vm.hasMoreRemoteFiles ? 1 : 0),
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
                        return _FileGridTile(
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

  Future<void> _openPreview(
    BuildContext context,
    BrowserViewModel vm,
    RemoteFile file,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FilePreviewScreen(
          file: file,
          onDownload: () => vm.downloadFile(file),
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
                    RemoteSortField.size => 'TamaÃ±o',
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
                    child: Text('TamaÃ±o'),
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

class _FileGridTile extends StatelessWidget {
  final RemoteFile file;
  final String remotePath;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  const _FileGridTile({
    super.key,
    required this.file,
    required this.remotePath,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceVariant.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _GridPreview(file: file, remotePath: remotePath)),
              const SizedBox(height: 6),
              Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      file.isDirectory
                          ? 'Carpeta'
                          : FileUtils.fileCategory(file.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.onSurfaceMuted,
                      ),
                    ),
                  ),
                  if (!file.isDirectory) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          FileUtils.extensionOf(file.name).isEmpty
                              ? 'FILE'
                              : FileUtils.extensionOf(file.name).toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: FileUtils.fileColor(
                              file.name,
                              isDirectory: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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
    final thumbFile = thumbPath == null ? null : File(thumbPath);
    final hasThumb = thumbFile != null && thumbFile.existsSync();
    final icon = FileUtils.fileIcon(
      widget.file.name,
      isDirectory: widget.file.isDirectory,
    );
    final color = FileUtils.fileColor(
      widget.file.name,
      isDirectory: widget.file.isDirectory,
    );

    if (widget.file.isDirectory) {
      return _FileFrame(
        color: color,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 58, color: color),
              const SizedBox(height: 6),
              const Text(
                'Carpeta',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!hasThumb) {
      if (FileUtils.isImage(widget.file.name) ||
          FileUtils.isVideo(widget.file.name)) {
        _scheduleThumbnailRequest();
      }
      return _FileFrame(
        color: color,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 52, color: color),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  FileUtils.extensionOf(widget.file.name).toUpperCase().isEmpty
                      ? 'FILE'
                      : FileUtils.extensionOf(widget.file.name).toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.file(
                  thumbFile!,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  cacheWidth: 256,
                  cacheHeight: 256,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    return _FileFrame(
                      color: color,
                      child: Icon(icon, size: 54, color: color),
                    );
                  },
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  FileUtils.extensionOf(widget.file.name).isEmpty
                      ? 'FILE'
                      : FileUtils.extensionOf(widget.file.name).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileFrame extends StatelessWidget {
  final Widget child;
  final Color color;

  const _FileFrame({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            AppTheme.surfaceVariant.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(child: child),
    );
  }
}

class _FilePreviewScreen extends StatefulWidget {
  final RemoteFile file;
  final Future<void> Function() onDownload;
  final FtpProfile profile;
  final IDownloadFileUseCase downloadFileUseCase;

  const _FilePreviewScreen({
    required this.file,
    required this.onDownload,
    required this.profile,
    required this.downloadFileUseCase,
  });

  @override
  State<_FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<_FilePreviewScreen> {
  late final Future<String?> _previewFileFuture;
  late final _PreviewKind _previewKind;

  @override
  void initState() {
    super.initState();
    _previewKind = _previewKindFor(widget.file.name);
    _previewFileFuture = _loadPreviewFile();
  }

  @override
  Widget build(BuildContext context) {
    final icon = FileUtils.fileIcon(widget.file.name, isDirectory: widget.file.isDirectory);
    final color = FileUtils.fileColor(widget.file.name, isDirectory: widget.file.isDirectory);
    final isMedia = _previewKind != _PreviewKind.other && !widget.file.isDirectory;

    return Scaffold(
      backgroundColor: isMedia ? Colors.black : AppTheme.background,
      extendBodyBehindAppBar: isMedia,
      appBar: AppBar(
        title: Text(widget.file.name),
        backgroundColor: isMedia ? Colors.black.withValues(alpha: 0.35) : null,
        foregroundColor: isMedia ? Colors.white : null,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Ver detalles',
            onPressed: () => _showDetailsSheet(context),
            icon: const Icon(Icons.info_outline),
          ),
          if (!widget.file.isDirectory)
            IconButton(
              tooltip: 'Descargar',
              onPressed: () async {
                await widget.onDownload();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Descarga iniciada')),
                  );
                }
              },
              icon: const Icon(Icons.download),
            ),
        ],
      ),
      body: widget.file.isDirectory
          ? SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                  colors: [
                                    color.withValues(alpha: 0.22),
                                    AppTheme.surfaceVariant,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.35),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Center(
                                  child: Icon(icon, size: 120, color: color),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.file.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            FileUtils.fileCategory(
                              widget.file.name,
                              isDirectory: widget.file.isDirectory,
                            ),
                            style: const TextStyle(color: AppTheme.onSurfaceMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            )
          : FutureBuilder<String?>(
              future: _previewFileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No se pudo preparar la vista previa',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  );
                }

                final previewPath = snapshot.data;
                if (previewPath == null || !File(previewPath).existsSync()) {
                  return _buildOtherFileView(icon, color);
                }

                return switch (_previewKind) {
                  _PreviewKind.image => _ImagePreviewViewport(filePath: previewPath),
                  _PreviewKind.video => _VideoPreviewViewport(filePath: previewPath),
                  _PreviewKind.pdf => SafeArea(
                      child: SfPdfViewer.file(File(previewPath)),
                    ),
                  _PreviewKind.other => _buildOtherFileView(icon, color),
                };
              },
            ),
    );
  }

  Widget _buildOtherFileView(IconData icon, Color color) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.22),
                    AppTheme.surfaceVariant,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Center(
                  child: Icon(icon, size: 120, color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _PreviewKind _previewKindFor(String fileName) {
    if (FileUtils.isImage(fileName)) return _PreviewKind.image;
    if (FileUtils.isVideo(fileName)) return _PreviewKind.video;
    if (FileUtils.extensionOf(fileName) == 'pdf') return _PreviewKind.pdf;
    return _PreviewKind.other;
  }

  Future<String?> _loadPreviewFile() async {
    if (_previewKind == _PreviewKind.other) return null;
    if (kIsWeb && _previewKind == _PreviewKind.video) return null;

    final tempDir = await getTemporaryDirectory();
    final previewDir = Directory(p.join(tempDir.path, 'hotftp_preview_cache'));
    await previewDir.create(recursive: true);

    final hashInput = '${widget.file.path}|${widget.file.size}|${widget.file.modifiedAt?.toIso8601String() ?? ''}';
    final key = sha1.convert(utf8.encode(hashInput)).toString();
    final ext = FileUtils.extensionOf(widget.file.name).isEmpty
        ? 'bin'
        : FileUtils.extensionOf(widget.file.name);
    final previewPath = p.join(previewDir.path, '$key.$ext');
    final previewFile = File(previewPath);
    if (await previewFile.exists()) return previewPath;

    await widget.downloadFileUseCase.execute(widget.file, previewPath, widget.profile);
    return previewPath;
  }

  Future<void> _showDetailsSheet(BuildContext context) async {
    final ext = FileUtils.extensionOf(widget.file.name).isEmpty
        ? 'N/A'
        : FileUtils.extensionOf(widget.file.name).toUpperCase();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          widthFactor: 1,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalles',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.file.name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Nombre',
                      value: widget.file.name,
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Extensión',
                      value: ext,
                      icon: Icons.extension_outlined,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Tipo',
                      value: FileUtils.fileCategory(
                        widget.file.name,
                        isDirectory: widget.file.isDirectory,
                      ),
                      icon: Icons.category_outlined,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Tamaño',
                      value: widget.file.isDirectory
                          ? 'Carpeta'
                          : FileUtils.formatBytes(widget.file.size),
                      icon: Icons.sd_storage_outlined,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Fecha',
                      value: widget.file.modifiedAt == null
                          ? 'Sin fecha'
                          : '${widget.file.modifiedAt!.day.toString().padLeft(2, '0')}/${widget.file.modifiedAt!.month.toString().padLeft(2, '0')}/${widget.file.modifiedAt!.year} ${widget.file.modifiedAt!.hour.toString().padLeft(2, '0')}:${widget.file.modifiedAt!.minute.toString().padLeft(2, '0')}',
                      icon: Icons.schedule_outlined,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Ruta',
                      value: widget.file.path,
                      icon: Icons.route_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _PreviewKind { image, video, pdf, other }

class _ImagePreviewViewport extends StatefulWidget {
  final String filePath;

  const _ImagePreviewViewport({required this.filePath});

  @override
  State<_ImagePreviewViewport> createState() => _ImagePreviewViewportState();
}

class _ImagePreviewViewportState extends State<_ImagePreviewViewport> {
  late final Future<ui.Size> _imageSizeFuture;

  @override
  void initState() {
    super.initState();
    _imageSizeFuture = _loadImageSize(widget.filePath);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Size>(
      future: _imageSizeFuture,
      builder: (context, snapshot) {
        final imageSize = snapshot.data ?? const ui.Size(1, 1);
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenAspect = constraints.maxWidth / constraints.maxHeight;
            final imageAspect = imageSize.width / imageSize.height;
            final fit = imageAspect > screenAspect
                ? BoxFit.fitWidth
                : BoxFit.fitHeight;

            return Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(widget.filePath),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.low,
                ),
                Container(color: Colors.black.withValues(alpha: 0.25)),
                Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: FittedBox(
                      fit: fit,
                      child: SizedBox(
                        width: imageSize.width,
                        height: imageSize.height,
                        child: Image.file(
                          File(widget.filePath),
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<ui.Size> _loadImageSize(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    final size = ui.Size(
      frameInfo.image.width.toDouble(),
      frameInfo.image.height.toDouble(),
    );
    codec.dispose();
    return size;
  }
}

class _VideoPreviewViewport extends StatefulWidget {
  final String filePath;

  const _VideoPreviewViewport({required this.filePath});

  @override
  State<_VideoPreviewViewport> createState() => _VideoPreviewViewportState();
}

class _VideoPreviewViewportState extends State<_VideoPreviewViewport> {
  late final VideoPlayerController _controller;
  late final Future<void> _initFuture;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath));
    _initFuture = _controller.initialize().then((_) {
      _controller.setLooping(true);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_controller.value.isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _controlsVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !_controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return GestureDetector(
          onTap: () {
            setState(() {
              _controlsVisible = !_controlsVisible;
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.black),
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              if (_controlsVisible)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: VideoProgressColors(
                              playedColor: Colors.white,
                              bufferedColor: Colors.white54,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _togglePlay,
                                icon: Icon(
                                  _controller.value.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Vídeo',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatDuration(_controller.value.position),
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inHours}:$minutes:$seconds';
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
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, height: 1.25),
                ),
              ],
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






