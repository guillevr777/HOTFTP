import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:universal_io/io.dart';
import 'package:video_player/video_player.dart';

import '../../../domain/entities/local_file.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/file_utils.dart';

class LocalBrowserFilePreviewScreen extends StatefulWidget {
  final LocalFile file;
  final Future<bool> Function(LocalFile file)? onRepairRequested;

  const LocalBrowserFilePreviewScreen({
    super.key,
    required this.file,
    this.onRepairRequested,
  });

  @override
  State<LocalBrowserFilePreviewScreen> createState() => _LocalBrowserFilePreviewScreenState();
}

class _LocalBrowserFilePreviewScreenState extends State<LocalBrowserFilePreviewScreen> {
  late _PreviewKind _kind;
  String? _text;
  String? _problem;
  bool _loading = true;
  VideoPlayerController? _video;

  String get _name => widget.file.name;
  String get _path => widget.file.path;

  @override
  void initState() {
    super.initState();
    _kind = _kindFor(_name);
    _load();
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = FileUtils.fileIcon(_name, isDirectory: widget.file.isDirectory);
    final color = FileUtils.fileColor(_name, isDirectory: widget.file.isDirectory);
    final isMedia = _kind == _PreviewKind.image || _kind == _PreviewKind.video || _kind == _PreviewKind.pdf;

    return Scaffold(
      backgroundColor: isMedia ? Colors.black : AppTheme.background,
      appBar: AppBar(
        title: Text(_name),
        backgroundColor: isMedia ? Colors.black.withValues(alpha: 0.35) : null,
        foregroundColor: isMedia ? Colors.white : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _problem != null
              ? _ProblemView(message: _problem!)
              : widget.file.isDirectory
                  ? _DirectoryView(name: _name, icon: icon, color: color)
                  : switch (_kind) {
                      _PreviewKind.image => _ImageView(path: _path),
                      _PreviewKind.video => _VideoView(controller: _video),
                      _PreviewKind.pdf => SafeArea(child: SfPdfViewer.file(File(_path))),
                      _PreviewKind.text => _TextView(name: _name, text: _text ?? '(Archivo vacio)'),
                      _PreviewKind.other => _UnsupportedView(name: _name, icon: icon, color: color),
                    },
    );
  }

  _PreviewKind _kindFor(String fileName) {
    if (FileUtils.isImage(fileName)) return _PreviewKind.image;
    if (FileUtils.isVideo(fileName)) return _PreviewKind.video;
    if (FileUtils.extensionOf(fileName) == 'pdf') return _PreviewKind.pdf;
    if (FileUtils.isTextFile(fileName)) return _PreviewKind.text;
    return _PreviewKind.other;
  }

  Future<void> _load() async {
    try {
      final file = File(_path);
      if (!await _ensureReadableFile(file)) {
        return;
      }

      if (_kind == _PreviewKind.text) {
        try {
          _text = await file.readAsString();
        } catch (_) {
          _text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
        }
      } else if (_kind == _PreviewKind.video) {
        final controller = VideoPlayerController.file(file);
        _video = controller;
        await controller.initialize();
        await controller.play();
        controller.setLooping(true);
      }
    } catch (_) {
      _problem = 'No se pudo abrir este archivo.';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool> _ensureReadableFile(File file) async {
    final exists = await file.exists();
    final isText = _kind == _PreviewKind.text;
    if (!exists || (!isText && await file.length() == 0)) {
      final repaired = await widget.onRepairRequested?.call(widget.file) ?? false;
      if (repaired) {
        return _ensureReadableFile(file);
      }
      _problem = exists
          ? 'El archivo esta vacio o la descarga no se completo.'
          : 'El archivo no existe en el dispositivo.';
      return false;
    }
    return true;
  }
}

enum _PreviewKind { image, video, pdf, text, other }

class _DirectoryView extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;

  const _DirectoryView({required this.name, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 96, color: color),
          const SizedBox(height: 16),
          Text(name),
        ],
      ),
    );
  }
}

class _ImageView extends StatelessWidget {
  final String path;
  const _ImageView({required this.path});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No se pudo mostrar esta imagen.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoView extends StatelessWidget {
  final VideoPlayerController? controller;
  const _VideoView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio,
        child: VideoPlayer(c),
      ),
    );
  }
}

class _TextView extends StatelessWidget {
  final String name;
  final String text;
  const _TextView({required this.name, required this.text});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(name, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(text),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnsupportedView extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  const _UnsupportedView({required this.name, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 88, color: color),
          const SizedBox(height: 16),
          Text(name),
          const SizedBox(height: 8),
          const Text('Formato sin vista previa integrada.'),
        ],
      ),
    );
  }
}

class _ProblemView extends StatelessWidget {
  final String message;
  const _ProblemView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 72, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

