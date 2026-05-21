import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:universal_io/io.dart';
import 'package:video_player/video_player.dart';

import '../../../utils/thumbnail_utils.dart';

import '../../../domain/entities/ftp_profile.dart';
import '../../../domain/entities/remote_file.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/file_utils.dart';
import '../../../domain/interfaces/i_download_file_use_case.dart';

class BrowserFilePreviewScreen extends StatefulWidget {
  final RemoteFile file;
  final Future<void> Function(void Function(double progress) onProgress) onDownload;
  final FtpProfile profile;
  final IDownloadFileUseCase downloadFileUseCase;

  const BrowserFilePreviewScreen({
    super.key,
    required this.file,
    required this.onDownload,
    required this.profile,
    required this.downloadFileUseCase,
  });

  @override
  State<BrowserFilePreviewScreen> createState() =>
      _BrowserFilePreviewScreenState();
}

class _BrowserFilePreviewScreenState extends State<BrowserFilePreviewScreen> {
  static const Duration _previewDownloadTimeout = Duration(minutes: 5);

  late final _PreviewKind _previewKind;
  String? _previewPath;
  String? _previewPosterPath;
  String? _textPreviewContent;
  bool _previewLoading = true;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _previewKind = _previewKindFor(widget.file.name);
    _initPreview();
  }

  Future<void> _downloadFile(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });
    try {
      await widget.onDownload((progress) {
        if (!mounted) return;
        setState(() {
          _downloadProgress = progress.clamp(0.0, 1.0).toDouble();
        });
      });
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Descarga completada')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Widget _buildDownloadBanner() {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: _downloadProgress <= 0 ? null : _downloadProgress,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Descargando archivo... ${(100 * _downloadProgress).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon = FileUtils.fileIcon(
      widget.file.name,
      isDirectory: widget.file.isDirectory,
    );
    final color = FileUtils.fileColor(
      widget.file.name,
      isDirectory: widget.file.isDirectory,
    );
    final isMedia =
        (_previewKind == _PreviewKind.image ||
            _previewKind == _PreviewKind.video ||
            _previewKind == _PreviewKind.pdf) &&
        !widget.file.isDirectory;
    final bodyContent = widget.file.isDirectory
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
                          style: const TextStyle(
                            color: AppTheme.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          )
        : _buildPreviewBody(icon, color);

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
              onPressed: _isDownloading ? null : () => _downloadFile(context),
              icon: _isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isDownloading) _buildDownloadBanner(),
          Expanded(child: bodyContent),
        ],
      ),
    );
  }

  Widget _buildPreviewBody(IconData icon, Color color) {
    if (_previewLoading && _previewPath == null) {
      return _buildLoadingPreviewBody(icon, color);
    }

    final previewPath = _previewPath;
    final textPreview = _textPreviewContent;

    if (_previewKind == _PreviewKind.text) {
      if (textPreview == null) {
        return _buildOtherFileView(icon, color);
      }
      return _TextPreviewViewport(
        fileName: widget.file.name,
        text: textPreview,
      );
    }

    if (previewPath == null || !File(previewPath).existsSync()) {
      return _buildOtherFileView(icon, color);
    }

    return switch (_previewKind) {
      _PreviewKind.image => _ImagePreviewViewport(filePath: previewPath),
      _PreviewKind.video => _VideoPreviewViewport(
        filePath: previewPath,
        posterPath: _previewPosterPath,
      ),
      _PreviewKind.pdf => SafeArea(child: SfPdfViewer.file(File(previewPath))),
      _PreviewKind.text => _TextPreviewViewport(
        fileName: widget.file.name,
        text: textPreview ?? '',
      ),
      _PreviewKind.other => _buildOtherFileView(icon, color),
    };
  }

  Widget _buildLoadingPreviewBody(IconData icon, Color color) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 88, color: color),
                                const SizedBox(height: 18),
                                const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    'Preparando vista previa',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.onSurfaceMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.file.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La vista previa se descargara y se guardara en cache.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
            ),
          );
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
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Center(child: Icon(icon, size: 120, color: color)),
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
    if (FileUtils.isTextFile(fileName)) return _PreviewKind.text;
    return _PreviewKind.other;
  }

  Future<String?> _loadPreviewFile() async {
    if (_previewKind == _PreviewKind.other) return null;
    if (kIsWeb && _previewKind == _PreviewKind.video) return null;

    final tempDir = await getTemporaryDirectory();
    final previewDir = Directory(p.join(tempDir.path, 'hotftp_preview_cache'));
    await previewDir.create(recursive: true);

    final hashInput =
        '${widget.file.path}|${widget.file.size}|${widget.file.modifiedAt?.toIso8601String() ?? ''}';
    final key = sha1.convert(utf8.encode(hashInput)).toString();
    final sourceDir = Directory(p.join(previewDir.path, '$key.source'));
    await sourceDir.create(recursive: true);
    final sourcePath = p.join(sourceDir.path, widget.file.name);
    final sourceFile = File(sourcePath);
    if (await sourceFile.exists()) {
      try {
        if (widget.file.size <= 0 || await sourceFile.length() == widget.file.size) {
          return sourcePath;
        }
      } catch (_) {
        await sourceFile.delete().catchError((_) => sourceFile);
      }
      await sourceFile.delete().catchError((_) => sourceFile);
    }

    await widget.downloadFileUseCase
        .execute(widget.file, sourceDir.path, widget.profile)
        .timeout(_previewDownloadTimeout);

    return sourcePath;
  }

  Future<void> _initPreview() async {
    if (_previewKind == _PreviewKind.other) {
      setState(() {
        _previewLoading = false;
      });
      return;
    }

    try {
      final previewPath = await _loadPreviewFile();
      String? textPreview;
      String? posterPath;
      if (_previewKind == _PreviewKind.text && previewPath != null) {
        textPreview = await _readTextPreview(previewPath);
      } else if (_previewKind == _PreviewKind.video && previewPath != null) {
        final posterFileName = '${p.basenameWithoutExtension(previewPath)}.poster.png';
        posterPath = p.join(p.dirname(previewPath), posterFileName);
        try {
          posterPath = await ThumbnailUtils.buildVideoThumbnailFromFile(
            sourcePath: previewPath,
            thumbnailPath: posterPath,
            maxDimension: 720,
            timeMs: 1,
          );
        } catch (_) {
          posterPath = null;
        }
      }
      if (!mounted) return;
      setState(() {
        if (_previewKind == _PreviewKind.text) {
          _textPreviewContent = textPreview;
        } else {
          _previewPath = previewPath;
          _previewPosterPath = posterPath;
        }
        _previewLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _previewLoading = false;
      });
    }
  }

  Future<String> _readTextPreview(String path) async {
    try {
      return await File(path).readAsString();
    } catch (_) {
      final bytes = await File(path).readAsBytes();
      return utf8.decode(bytes, allowMalformed: true);
    }
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
                      label: 'Extension',
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
                      label: 'Tamano',
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

enum _PreviewKind { image, video, pdf, text, other }

class _ImagePreviewViewport extends StatelessWidget {
  final String filePath;

  const _ImagePreviewViewport({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Image.file(
                File(filePath),
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No se pudo mostrar la imagen',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VideoPreviewViewport extends StatefulWidget {
  final String filePath;
  final String? posterPath;

  const _VideoPreviewViewport({required this.filePath, this.posterPath});

  @override
  State<_VideoPreviewViewport> createState() => _VideoPreviewViewportState();
}

class _VideoPreviewViewportState extends State<_VideoPreviewViewport> {
  VideoPlayerController? _controller;
  Future<void>? _initFuture;
  bool _controlsVisible = true;
  bool _isPreparing = false;
  bool _hasStarted = false;
  String? _initErrorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startPlayback() async {
    if (_isPreparing || _hasStarted) return;
    setState(() {
      _isPreparing = true;
      _initErrorMessage = null;
    });

    final controller = VideoPlayerController.file(File(widget.filePath));
    _controller = controller;
    _initFuture = controller.initialize();

    try {
      await _initFuture;
      controller.setLooping(true);
      await controller.play();
      if (!mounted) return;
      setState(() {
        _hasStarted = true;
        _controlsVisible = true;
        _isPreparing = false;
      });
    } catch (error) {
      await controller.dispose();
      _controller = null;
      _initFuture = null;
      if (!mounted) return;
      setState(() {
        _initErrorMessage = _describePlaybackError(error);
        _isPreparing = false;
      });
    }
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
      _controlsVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initErrorMessage != null) {
      return _VideoPreviewFallback(
        fileName: widget.filePath.split(Platform.pathSeparator).last,
        message: _initErrorMessage!,
      );
    }

    final controller = _controller;
    if (!_hasStarted || controller == null) {
      return _VideoPreviewPoster(
        fileName: widget.filePath.split(Platform.pathSeparator).last,
        posterPath: widget.posterPath,
        isPreparing: _isPreparing,
        onPlayPressed: _startPlayback,
      );
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
          LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              );
            },
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
                        controller,
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
                              controller.value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Video',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatDuration(controller.value.position),
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
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inHours}:$minutes:$seconds';
  }
}

class _VideoPreviewFallback extends StatelessWidget {
  final String fileName;
  final String message;

  const _VideoPreviewFallback({
    required this.fileName,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                size: 72,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                fileName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              const Text(
                'Si el archivo llegó completo y sigue sin abrir, lo más probable es que el códec no sea compatible con el reproductor del dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _describePlaybackError(Object error) {
  final raw = error.toString();
  final lower = raw.toLowerCase();
  if (lower.contains('timeout')) {
    return 'La vista previa tardó demasiado en descargarse. Puede ser una conexión lenta o un vídeo grande.';
  }
  if (lower.contains('format') ||
      lower.contains('codec') ||
      lower.contains('mediacodec') ||
      lower.contains('unsupported')) {
    return 'El archivo se descargó, pero el reproductor del dispositivo no entiende este códec o contenedor.';
  }
  return 'La reproducción falló al preparar el vídeo. Detalle técnico: $raw';
}

class _VideoPreviewPoster extends StatelessWidget {
  final String fileName;
  final String? posterPath;
  final bool isPreparing;
  final VoidCallback onPlayPressed;

  const _VideoPreviewPoster({
    required this.fileName,
    required this.posterPath,
    required this.isPreparing,
    required this.onPlayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox.expand(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                fit: StackFit.expand,
                                alignment: Alignment.center,
                                children: [
                                  if (posterPath != null && File(posterPath!).existsSync())
                                    Image.file(
                                      File(posterPath!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const ColoredBox(color: Colors.black);
                                      },
                                    )
                                  else
                                    const ColoredBox(color: Colors.black),
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0x22000000),
                                          Color(0xAA000000),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Center(
                                    child: Icon(
                                      Icons.movie_outlined,
                                      color: Colors.white54,
                                      size: 88,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 16,
                                    child: FilledButton.icon(
                                      onPressed: isPreparing ? null : onPlayPressed,
                                      icon: isPreparing
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.play_arrow),
                                      label: Text(
                                        isPreparing ? 'Preparando' : 'Reproducir',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          fileName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'El video solo se cargara al pulsar reproducir.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TextPreviewViewport extends StatelessWidget {
  final String fileName;
  final String text;

  const _TextPreviewViewport({required this.fileName, required this.text});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: AppTheme.background,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.text_snippet_outlined,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  text.isEmpty ? '(Archivo vacio)' : text,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    height: 1.45,
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




