import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/ftp_profile.dart';
import '../../../theme/app_theme.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/profile_view_model.dart';
import '../auth/account_screen.dart';
import '../browser/remote_browser_screen.dart';
import '../monitoring/health_center_screen.dart';
import 'profile_form_screen.dart';

class ProfileListScreen extends StatefulWidget {
  final String ownerId;

  const ProfileListScreen({super.key, required this.ownerId});

  @override
  State<ProfileListScreen> createState() => _ProfileListScreenState();
}

class _ProfileListScreenState extends State<ProfileListScreen> {
  @override
  Widget build(BuildContext context) {
    final profileVm = context.watch<ProfileViewModel>();
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.cloud_sync, color: AppTheme.primary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HOTFTP'),
                Text(
                  authVm.currentUser?.displayName ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mi cuenta',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Centro de salud',
            icon: const Icon(Icons.health_and_safety_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HealthCenterScreen(ownerId: widget.ownerId),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: authVm.isLoading
                ? null
                : () async {
                    await authVm.logout();
                  },
          ),
        ],
      ),
      body: profileVm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileVm.profiles.isEmpty
          ? _buildEmptyState(context)
          : _buildProfileList(context, profileVm),
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

  Future<void> _openForm(BuildContext context, FtpProfile? profile) async {
    final vm = context.read<ProfileViewModel>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: ProfileFormScreen(profile: profile),
        ),
      ),
    );
    if (mounted) {
      await vm.loadProfiles();
    }
  }

  void _connect(BuildContext context, FtpProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RemoteBrowserScreen(profile: profile, ownerId: widget.ownerId),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ProfileViewModel vm,
    FtpProfile profile,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar perfil'),
        content: Text('Eliminar "${profile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.deleteProfile(profile);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.error),
            ),
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
                        profile.host,
                        style: const TextStyle(
                          color: AppTheme.onSurfaceMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _TransportBadge(transportType: profile.transportType),
                          const SizedBox(width: 8),
                          _ProtocolBadge(protocol: profile.protocol),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onConnect,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransportBadge extends StatelessWidget {
  final FtpTransportType transportType;

  const _TransportBadge({required this.transportType});

  @override
  Widget build(BuildContext context) {
    final isDirect = transportType == FtpTransportType.direct;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isDirect ? AppTheme.success : AppTheme.primary).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isDirect ? 'Directo' : 'API',
        style: TextStyle(
          color: isDirect ? AppTheme.success : AppTheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProtocolBadge extends StatelessWidget {
  final FtpProtocolType protocol;

  const _ProtocolBadge({required this.protocol});

  @override
  Widget build(BuildContext context) {
    final color = switch (protocol) {
      FtpProtocolType.ftp => AppTheme.primary,
      FtpProtocolType.sftp => AppTheme.warning,
      FtpProtocolType.ftps => AppTheme.success,
    };
    final label = switch (protocol) {
      FtpProtocolType.ftp => 'FTP',
      FtpProtocolType.sftp => 'SFTP',
      FtpProtocolType.ftps => 'FTPS',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
