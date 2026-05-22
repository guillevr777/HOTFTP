import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/profile_view_model.dart';
import '../profiles/profile_list_screen.dart';
import 'login_screen.dart';
import '../../../domain/interfaces/i_delete_profile_use_case.dart';
import '../../../domain/interfaces/i_get_profiles_use_case.dart';
import '../../../domain/interfaces/i_record_event_use_case.dart';
import '../../../domain/interfaces/i_save_profile_use_case.dart';
import '../../../domain/interfaces/i_test_connection_use_case.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authVm.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    return _AuthenticatedHome(key: ValueKey(user.uid), ownerId: user.uid);
  }
}

class _AuthenticatedHome extends StatefulWidget {
  final String ownerId;

  const _AuthenticatedHome({super.key, required this.ownerId});

  @override
  State<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<_AuthenticatedHome> {
  late final ProfileViewModel _profileVm;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _profileVm = ProfileViewModel(
      getProfiles: context.read<IGetProfilesUseCase>(),
      saveProfile: context.read<ISaveProfileUseCase>(),
      deleteProfile: context.read<IDeleteProfileUseCase>(),
      testConnectionUseCase: context.read<ITestConnectionUseCase>(),
      recordEvent: context.read<IRecordEventUseCase>(),
      ownerId: widget.ownerId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loaded) return;
      _loaded = true;
      _profileVm.loadProfiles();
    });
  }

  @override
  void dispose() {
    _profileVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _profileVm,
      child: ProfileListScreen(ownerId: widget.ownerId),
    );
  }
}
