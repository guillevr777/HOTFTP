import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../viewmodels/auth_view_model.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await vm.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(vm.error ?? 'No se pudo iniciar sesion'),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  Future<void> _loginWithGoogle(AuthViewModel vm) async {
    final ok = await vm.loginWithGoogle();
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(vm.error ?? 'No se pudo iniciar con Google'),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  Future<void> _forgotPassword(AuthViewModel vm) async {
    final email = _emailController.text.trim();
    final confirmedEmail = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final dialogController = TextEditingController(text: email);
        return AlertDialog(
          title: const Text('Recuperar contraseña'),
          content: TextField(
            controller: dialogController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'usuario@dominio.com',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, dialogController.text.trim()),
              child: const Text('Enviar enlace'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmedEmail == null || confirmedEmail.isEmpty) return;
    final ok = await vm.sendPasswordResetEmail(confirmedEmail);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Te hemos enviado un correo para restablecer la contraseña. Revisa también spam.'
              : vm.error ?? 'No se pudo enviar el correo de recuperación',
        ),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF08141F), Color(0xFF0D1117), Color(0xFF101B2D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.cloud_sync,
                            size: 56,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'HOTFTP',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Accede con tu correo o inicia sesión con Google.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.onSurfaceMuted),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Introduce tu correo';
                              }
                              if (!value.contains('@')) {
                                return 'Introduce un correo válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Introduce tu contraseña'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: vm.isLoading ? null : () => _submit(vm),
                            icon: vm.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(
                              vm.isLoading ? 'Entrando...' : 'Iniciar sesión',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: vm.isLoading
                                  ? null
                                  : () => _forgotPassword(vm),
                              child: const Text(
                                '¿Has olvidado tu contraseña?',
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            onPressed: vm.isLoading
                                ? null
                                : () => _loginWithGoogle(vm),
                            icon: const Icon(Icons.g_mobiledata, size: 26),
                            label: const Text('Continuar con Google'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.onSurface,
                              side: const BorderSide(
                                color: AppTheme.surfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: vm.isLoading
                                ? null
                                : () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                            child: const Text('Crear cuenta nueva'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
