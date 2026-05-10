import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/recurring_dump_service.dart';
import '../../../domain/repositories/ftp_repository.dart';
import '../../../domain/repositories/monitoring_repository.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/profile_view_model.dart';
import '../profiles/profile_list_screen.dart';
import 'login_screen.dart';
import '../../../domain/interfaces/i_delete_profile_use_case.dart';
import '../../../domain/interfaces/i_evaluate_sync_rules_use_case.dart';
import '../../../domain/interfaces/i_get_profiles_use_case.dart';
import '../../../domain/interfaces/i_save_profile_use_case.dart';
import '../../../domain/interfaces/i_test_connection_use_case.dart';

class AuthGate extends StatefulWidget {
  final FtpRepository ftpRepository;
  final MonitoringRepository monitoringRepository;
  final IEvaluateSyncRulesUseCase evaluateSyncRules;

  const AuthGate({
    super.key,
    required this.ftpRepository,
    required this.monitoringRepository,
    required this.evaluateSyncRules,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final RecurringDumpService _recurringDumpService;
  String? _activeOwnerId;
  Timer? _recurringStartDelay;

  @override
  void initState() {
    super.initState();
    _recurringDumpService = RecurringDumpService(
      widget.ftpRepository,
      monitoringRepository: widget.monitoringRepository,
      evaluateSyncRules: widget.evaluateSyncRules,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    _recurringStartDelay?.cancel();
    _recurringDumpService.stop();
    super.dispose();
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
      if (_activeOwnerId != null) {
        _recurringStartDelay?.cancel();
        _recurringDumpService.stop();
        _activeOwnerId = null;
      }
      return const LoginScreen();
    }

    if (_activeOwnerId != user.uid) {
      _activeOwnerId = user.uid;
      _recurringStartDelay?.cancel();
      _recurringStartDelay = Timer(const Duration(seconds: 8), () {
        if (!mounted || _activeOwnerId != user.uid) return;
        _recurringDumpService.start(user.uid);
      });
    }

    return ChangeNotifierProvider(
      create: (context) => ProfileViewModel(
        getProfiles: context.read<IGetProfilesUseCase>(),
        saveProfile: context.read<ISaveProfileUseCase>(),
        deleteProfile: context.read<IDeleteProfileUseCase>(),
        testConnectionUseCase: context.read<ITestConnectionUseCase>(),
        ownerId: user.uid,
      ),
      child: ProfileListScreen(ownerId: user.uid),
    );
  }
}




