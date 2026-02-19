import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../../domain/entities/ftp_profile.dart';
import 'profile_form_screen.dart';
import '../browser/remote_browser_screen.dart';
import '../../../theme/app_theme.dart';

class ProfileListScreen extends StatefulWidget {
  const ProfileListScreen({super.key});

  @override
  State<ProfileListScreen> createState() => _ProfileListScreenState();
}

class _ProfileListScreenState extends State<ProfileListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.cloud_sync, color: AppTheme.primary),
            const SizedBox(width: 10),
            const Text('HOTFTP'),
          ],
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.profiles.isEmpty
              ? _buildEmptyState(context)
              : _buildProfileList(context, vm),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo perfil'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 72, color: AppTheme.onSurfaceMuted),
          const SizedBox(height: 16),
          const Text(
            'No hay perfiles FTP',
            style: TextStyle(fontSize: 18, color: AppTheme.onSurfaceMuted),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea uno para empezar',
            style: TextStyle(color: AppTheme.onSurfaceMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openForm(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Crear perfil'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileList(BuildContext context, ProfileViewModel vm) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vm.profiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final profile = vm.profiles[i];
        return _ProfileCard(
          profile: profile,
          onConnect: () => _connect(context, profile),
          onEdit: () => _openForm(context, profile),
          onDelete: () => _confirmDelete(context, vm, profile),
        );
      },
    );
  }

      void _openForm(BuildContext context, FtpProfile? profile) async {
    final vm = context.read<ProfileViewModel>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileFormScreen(profile: profile)),
    );
    if (mounted) {
       vm.loadProfiles();
    }
  }

  void _connect(BuildContext context, FtpProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RemoteBrowserScreen(profile: profile)),
    );
  }

  void _confirmDelete(BuildContext context, ProfileViewModel vm, FtpProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar perfil'),
        content: Text('Eliminar "${profile.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.deleteProfile(profile.id!);
            },
            child: const Text('Eliminar', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final FtpProfile profile;
  final VoidCallback onConnect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProfileCard({
    required this.profile,
    required this.onConnect,
    required this.onEdit,
    required this.onDelete,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.dns, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${profile.host}:${profile.port}',
                        style: const TextStyle(
                          color: AppTheme.onSurfaceMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (profile.useFTPS)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'FTPS',
                      style: TextStyle(color: AppTheme.success, fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onConnect,
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Conectar'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}







