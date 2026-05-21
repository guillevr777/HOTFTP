import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/injection_container.dart';
import 'firebase_options.dart';
import 'presentation/views/auth/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        home: const AuthGate(),
      ),
    );
  }
}
