import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/ftp_profile.dart';
import '../../../domain/entities/remote_file.dart';
import '../../../utils/file_utils.dart';
import '../../viewmodels/browser_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../../theme/app_theme.dart';
import '../sync/sync_screen.dart';
import '../history/history_screen.dart';

class RemoteBrowserScreen extends StatelessWidget {
  final FtpProfile profile;
  const RemoteBrowserScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BrowserViewModel(
        repository: context.read<ProfileViewModel>().repository,
        profile: profile,
      )..loadRemoteFiles(),
      child: _RemoteBrowserBody(profile: profile),
    );
  }
}

class _RemoteBrowserBody extends StatelessWidget {
  final FtpProfile profile;
  const _RemoteBrowserBody({required this.profile});

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
              MaterialPageRoute(builder: (_) => SyncScreen(profile: profile)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryScreen(profile: profile),
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
                : vm.remoteFiles.isEmpty
                ? const Center(
                    child: Text(
                      'Carpeta vacia',
                      style: TextStyle(color: AppTheme.onSurfaceMuted),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => vm.loadRemoteFiles(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: vm.remoteFiles.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 56),
                      itemBuilder: (context, i) {
                        final file = vm.remoteFiles[i];
                        return _FileListTile(
                          file: file,
                          onTap: () {
                            if (file.isDirectory) {
                              vm.navigateRemote(file.name);
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
    final thumbnailPath = vm.thumbnails[file.name];

    Widget leading;
    if (thumbnailPath != null) {
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
          ? null
          : Text(_formatSize(file.size), style: const TextStyle(fontSize: 12)),
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
      iconColor = AppTheme.primary; // O un color que prefieras para vídeos
    }

    return Icon(iconData, color: iconColor, size: 28);
  }
}
