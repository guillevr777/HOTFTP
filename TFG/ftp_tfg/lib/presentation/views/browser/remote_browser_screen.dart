import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/ftp_profile.dart';
import '../../../domain/entities/remote_file.dart';
import '../../../theme/app_theme.dart';
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
      create: (context) => BrowserViewModel(
        getRemoteFiles: context.read<IGetRemoteFilesUseCase>(),
        getLocalFiles: context.read<IGetLocalFilesUseCase>(),
        downloadFileUseCase: context.read<IDownloadFileUseCase>(),
        uploadFileUseCase: context.read<IUploadFileUseCase>(),
        downloadThumbnailUseCase: context.read<IDownloadThumbnailUseCase>(),
        getLatestFileVersion: context.read<IGetLatestFileVersionUseCase>(),
        recordFileVersion: context.read<IRecordFileVersionUseCase>(),
        profile: profile,
        ownerId: ownerId,
      )..loadRemoteFiles(),
      child: _RemoteBrowserBody(
        profile: profile,
        ownerId: ownerId,
      ),
    );
  }
}

class _RemoteBrowserBody extends StatelessWidget {
  final FtpProfile profile;
  final String ownerId;

  const _RemoteBrowserBody({
    required this.profile,
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
          IconButton(
            onPressed: onGoUp,
            icon: const Icon(Icons.arrow_upward),
          ),
          Expanded(child: Text(path)),
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
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(file.isDirectory ? Icons.folder : Icons.insert_drive_file),
      title: Text(file.name),
      onTap: onTap,
      trailing: onDownload == null
          ? null
          : IconButton(
              icon: const Icon(Icons.download),
              onPressed: onDownload,
            ),
    );
  }
}




