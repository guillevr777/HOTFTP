import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_io/io.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/file_utils.dart';
import '../../viewmodels/browser_view_model.dart';
import '../../../domain/entities/remote_file.dart';

class BrowserFileGridTile extends StatelessWidget {
  final RemoteFile file;
  final String remotePath;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  const BrowserFileGridTile({
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
              Expanded(
                child: _BrowserGridPreview(file: file, remotePath: remotePath),
              ),
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

class _BrowserGridPreview extends StatefulWidget {
  final RemoteFile file;
  final String remotePath;

  const _BrowserGridPreview({required this.file, required this.remotePath});

  @override
  State<_BrowserGridPreview> createState() => _BrowserGridPreviewState();
}

class _BrowserGridPreviewState extends State<_BrowserGridPreview> {
  String? _requestedPath;
  bool _retryScheduledForCurrentThumb = false;

  @override
  void didUpdateWidget(covariant _BrowserGridPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _requestedPath = null;
      _retryScheduledForCurrentThumb = false;
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
        highPriority: true,
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
      return _BrowserFileFrame(
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
      return _BrowserFileFrame(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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

    final existingThumbFile = thumbFile;

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
                  existingThumbFile,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  cacheWidth: 180,
                  cacheHeight: 180,
                  filterQuality: FilterQuality.low,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    if (!_retryScheduledForCurrentThumb) {
                      _retryScheduledForCurrentThumb = true;
                      final vm = context.read<BrowserViewModel>();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        unawaited(() async {
                          if (!mounted) return;
                          vm.invalidateThumbnail(widget.file.path);
                          if (existingThumbFile.existsSync()) {
                            await existingThumbFile.delete();
                          }
                          _requestedPath = null;
                          _retryScheduledForCurrentThumb = false;
                          vm.requestThumbnail(
                            widget.file,
                            widget.remotePath,
                            highPriority: true,
                          );
                        }());
                      });
                    }
                    return _BrowserFileFrame(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

class _BrowserFileFrame extends StatelessWidget {
  final Widget child;
  final Color color;

  const _BrowserFileFrame({required this.child, required this.color});

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
