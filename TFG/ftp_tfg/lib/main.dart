import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/di/injection_container.dart';
import 'firebase_options.dart';
import 'presentation/views/auth/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.create();

    return MultiProvider(
      providers: dependencies.providers,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HOTFTP',
        theme: AppTheme.dark,
        home: AuthGate(
          ftpRepository: dependencies.ftpRepository,
          monitoringRepository: dependencies.monitoringRepository,
          evaluateSyncRules: dependencies.evaluateSyncRules,
        ),
      ),
    );
  }
}
