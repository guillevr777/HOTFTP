import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/repositories/ftp_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../profiles/profile_list_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  final FtpRepository ftpRepository;

  const AuthGate({
    super.key,
    required this.ftpRepository,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    if (authVm.isBootstrapping) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authVm.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(
        repository: widget.ftpRepository,
        ownerId: user.uid,
      ),
      child: const ProfileListScreen(),
    );
  }
}
