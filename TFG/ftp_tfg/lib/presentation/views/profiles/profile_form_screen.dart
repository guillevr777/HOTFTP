import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/ftp_profile.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../../theme/app_theme.dart';

class ProfileFormScreen extends StatefulWidget {
  final FtpProfile? profile;
  const ProfileFormScreen({super.key, this.profile});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _user;
  late final TextEditingController _pass;
  bool _useFTPS = false;
  bool _passiveMode = true;
  bool _obscurePass = true;

  bool get isEditing => widget.profile != null;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p?.name ?? '');
    _host = TextEditingController(text: p?.host ?? '');
    _port = TextEditingController(text: (p?.port ?? 21).toString());
    _user = TextEditingController(text: p?.username ?? '');
    _pass = TextEditingController(text: p?.password ?? '');
    _useFTPS = p?.useFTPS ?? false;
    _passiveMode = p?.passiveMode ?? true;
  }

  @override
  void dispose() {
    _name.dispose(); _host.dispose(); _port.dispose();
    _user.dispose(); _pass.dispose();
    super.dispose();
  }

  FtpProfile _buildProfile() => FtpProfile(
        id: widget.profile?.id,
        name: _name.text.trim(),
        host: _host.text.trim(),
        port: int.tryParse(_port.text) ?? 21,
        username: _user.text.trim(),
        password: _pass.text,
        useFTPS: _useFTPS,
        passiveMode: _passiveMode,
      );

  Future<void> _save(ProfileViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    await vm.saveProfile(_buildProfile());
    if (mounted) Navigator.pop(context);
  }

  Future<void> _testConnection(ProfileViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await vm.testConnection(_buildProfile());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Conexion exitosa' : 'No se pudo conectar'),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar perfil' : 'Nuevo perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel('Identificacion'),
              const SizedBox(height: 12),
              _Field(controller: _name, label: 'Nombre del perfil', icon: Icons.label_outline,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              _SectionLabel('Servidor'),
              const SizedBox(height: 12),
              _Field(controller: _host, label: 'Host / IP', icon: Icons.dns_outlined,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              _Field(controller: _port, label: 'Puerto', icon: Icons.settings_ethernet,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              _SectionLabel('Credenciales'),
              const SizedBox(height: 12),
              _Field(controller: _user, label: 'Usuario', icon: Icons.person_outline,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Contrasena',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _SectionLabel('Opciones de conexion'),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Usar FTPS (SSL/TLS)'),
                      subtitle: const Text('Cifrado de la conexion', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
                      value: _useFTPS,
                      activeThumbColor: AppTheme.primary,
                      onChanged: (v) => setState(() => _useFTPS = v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Modo pasivo'),
                      subtitle: const Text('Recomendado para la mayoria de redes', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
                      value: _passiveMode,
                      activeThumbColor: AppTheme.primary,
                      onChanged: (v) => setState(() => _passiveMode = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: vm.isTesting ? null : () => _testConnection(vm),
                icon: vm.isTesting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.wifi_tethering),
                label: Text(vm.isTesting ? 'Probando...' : 'Probar conexion'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _save(vm),
                icon: const Icon(Icons.save_outlined),
                label: Text(isEditing ? 'Guardar cambios' : 'Crear perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        validator: validator,
      );
}




