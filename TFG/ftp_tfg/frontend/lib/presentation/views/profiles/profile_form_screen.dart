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
  FtpTransportType _transportType = FtpTransportType.direct;
  bool _passiveMode = true;
  bool _obscurePass = true;
  FtpProtocolType _protocol = FtpProtocolType.ftp;

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
    _transportType = p?.transportType ?? FtpTransportType.direct;
    _passiveMode = p?.passiveMode ?? true;
    _protocol = p?.protocol ?? FtpProtocolType.ftp;
  }

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  FtpProfile _buildProfile() => FtpProfile(
        id: widget.profile?.id,
        ownerId: widget.profile?.ownerId,
        name: _name.text.trim(),
        host: _host.text.trim(),
        port: int.tryParse(_port.text) ?? 21,
        username: _user.text.trim(),
        password: _pass.text,
        transportType: _transportType,
        protocol: _protocol,
        passiveMode: _passiveMode,
      );

  String _protocolLabel(FtpProtocolType protocol) {
    return switch (protocol) {
      FtpProtocolType.ftp => 'FTP',
      FtpProtocolType.sftp => 'SFTP',
      FtpProtocolType.ftps => 'FTPS',
    };
  }

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
        title: Text(isEditing ? 'Editar conexion' : 'Nueva conexion'),
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
              _Field(
                controller: _name,
                label: 'Nombre del perfil',
                icon: Icons.label_outline,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _SectionLabel('Servidor'),
              const SizedBox(height: 12),
              _Field(
                controller: _host,
                label: 'Host / DNS / IP',
                icon: Icons.dns_outlined,
                helperText: 'Ej: test.rebex.net o 194.108.117.16',
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _port,
                label: 'Puerto',
                icon: Icons.settings_ethernet,
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _SectionLabel('Credenciales'),
              const SizedBox(height: 12),
              _Field(
                controller: _user,
                label: 'Usuario',
                icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Contrasena opcional',
                  prefixIcon: const Icon(Icons.lock_outline),
                  helperText: 'Deja este campo vacio si el servidor no requiere clave',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (_) => null,
              ),
              const SizedBox(height: 16),
              _SectionLabel('Opciones de conexion'),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    _ChoiceField<FtpTransportType>(
                      label: 'Ruta de conexion',
                      icon: Icons.alt_route_outlined,
                      value: _transportType,
                      items: const [
                        DropdownMenuItem(
                          value: FtpTransportType.direct,
                          child: Text('Directo'),
                        ),
                        DropdownMenuItem(
                          value: FtpTransportType.api,
                          child: Text('API'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _transportType = value);
                      },
                    ),
                    const Divider(height: 1),
                    _ChoiceField<FtpProtocolType>(
                      label: 'Protocolo FTP',
                      icon: Icons.cloud_sync_outlined,
                      value: _protocol,
                      items: const [
                        DropdownMenuItem(
                          value: FtpProtocolType.ftp,
                          child: Text('FTP'),
                        ),
                        DropdownMenuItem(
                          value: FtpProtocolType.sftp,
                          child: Text('SFTP'),
                        ),
                        DropdownMenuItem(
                          value: FtpProtocolType.ftps,
                          child: Text('FTPS'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _protocol = value;
                          final currentPort = int.tryParse(_port.text);
                          if (value == FtpProtocolType.sftp &&
                              (currentPort == null || currentPort == 21)) {
                            _port.text = '22';
                          } else if (value == FtpProtocolType.ftps &&
                              (currentPort == null ||
                                  currentPort == 22 ||
                                  currentPort == 21)) {
                            _port.text = '21';
                          } else if (value != FtpProtocolType.sftp &&
                              (currentPort == null || currentPort == 22)) {
                            _port.text = '21';
                          }
                        });
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.security_outlined),
                      title: const Text('Modo de cifrado'),
                      subtitle: Text(_protocolLabel(_protocol)),
                      trailing: Chip(
                        label: Text(
                          _protocol == FtpProtocolType.ftps
                              ? '21 explícito'
                              : _protocolLabel(_protocol),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Modo pasivo'),
                      subtitle: const Text(
                        'Recomendado para la mayoria de redes',
                        style: TextStyle(
                          color: AppTheme.onSurfaceMuted,
                          fontSize: 12,
                        ),
                      ),
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
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
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
  final ValueChanged<String>? onChanged;
  final String? helperText;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          helperText: helperText,
        ),
        validator: validator,
        onChanged: onChanged,
      );
}

class _ChoiceField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  const _ChoiceField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: (selected) {
            if (selected == null) return;
            onChanged(selected);
          },
        ),
      ),
    );
  }
}
