import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;
    final providers = user?.providers.toSet() ?? <String>{};
    final hasPasswordAccess = providers.contains('password');
    final hasGoogleAccess = providers.contains('google.com');

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? const Icon(
                            Icons.person,
                            color: AppTheme.primary,
                            size: 30,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'Sin correo',
                          style: const TextStyle(
                            color: AppTheme.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MethodChip(
                              label: 'Google',
                              icon: Icons.g_mobiledata,
                              active: hasGoogleAccess,
                            ),
                            _MethodChip(
                              label: 'Correo y contraseña',
                              icon: Icons.lock_outline,
                              active: hasPasswordAccess,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Acciones rápidas',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.link_outlined),
                  title: const Text('Vincular correo y contraseña'),
                  subtitle: Text(
                    hasPasswordAccess
                        ? 'Esta cuenta ya puede entrar con correo y contraseña.'
                        : 'Añade un acceso alternativo para entrar sin Google.',
                  ),
                  onTap:
                      authVm.isLoading ||
                          hasPasswordAccess ||
                          user?.email == null
                      ? null
                      : () async {
                          final passwordController = TextEditingController();
                          final confirmController = TextEditingController();
                          final password = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Vincular acceso'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Se usará el correo ${user?.email ?? ''} para crear el acceso con contraseña.',
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Nueva contraseña',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: confirmController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Confirmar contraseña',
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    final password = passwordController.text
                                        .trim();
                                    final confirm = confirmController.text
                                        .trim();
                                    if (password.isEmpty || confirm.isEmpty) {
                                      return;
                                    }
                                    if (password != confirm) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Las contraseñas no coinciden.',
                                          ),
                                          backgroundColor: AppTheme.error,
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.pop(ctx, password);
                                  },
                                  child: const Text('Vincular'),
                                ),
                              ],
                            ),
                          );
                          if (password == null || password.isEmpty) return;
                          final ok = await authVm.linkPasswordAccess(password);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Acceso con correo y contraseña vinculado.'
                                    : authVm.error ??
                                          'No se pudo vincular el acceso.',
                              ),
                              backgroundColor: ok
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                          );
                        },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Editar nombre'),
                  subtitle: const Text(
                    'Actualiza el nombre visible asociado a tu cuenta.',
                  ),
                  onTap: authVm.isLoading
                      ? null
                      : () async {
                          final controller = TextEditingController(
                            text: user?.displayName,
                          );
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Editar nombre'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre visible',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(
                                    ctx,
                                    controller.text.trim(),
                                  ),
                                  child: const Text('Guardar'),
                                ),
                              ],
                            ),
                          );
                          if (newName == null || newName.isEmpty) return;
                          final ok = await authVm.changeDisplayName(newName);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Nombre actualizado correctamente.'
                                    : authVm.error ??
                                          'No se pudo actualizar el nombre.',
                              ),
                              backgroundColor: ok
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                          );
                        },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: const Text('Reenviar correo de recuperación'),
                  subtitle: const Text(
                    'Disponible cuando la cuenta tiene acceso con contraseña.',
                  ),
                  onTap: user?.email == null || !hasPasswordAccess
                      ? null
                      : () async {
                          final ok = await authVm.sendPasswordResetEmail(
                            user!.email,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Correo de recuperación enviado.'
                                    : authVm.error ??
                                          'No se pudo enviar el correo.',
                              ),
                              backgroundColor: ok
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                          );
                        },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppTheme.error),
                  title: const Text('Cerrar sesión'),
                  subtitle: const Text('Salir de la cuenta actual.'),
                  onTap: authVm.isLoading ? null : () => authVm.logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;

  const _MethodChip({
    required this.label,
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        size: 18,
        color: active ? AppTheme.primary : AppTheme.onSurfaceMuted,
      ),
      label: Text(label),
      side: BorderSide(
        color: active
            ? AppTheme.primary.withValues(alpha: 0.5)
            : const Color(0xFF30363D),
      ),
      backgroundColor: active
          ? AppTheme.primary.withValues(alpha: 0.12)
          : AppTheme.surface,
      labelStyle: TextStyle(
        color: active ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
