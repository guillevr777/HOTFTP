import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/datasources/fake_datasource.dart';
import 'data/datasources/firebase_auth_datasource.dart';
import 'data/datasources/ftp_real_datasource.dart';
import 'data/repositories/firebase_auth_repository_impl.dart';
import 'data/repositories/ftp_repository.dart';
import 'domain/usecases/auth/login_user.dart';
import 'domain/usecases/auth/logout_user.dart';
import 'domain/usecases/auth/observe_auth_state.dart';
import 'domain/usecases/auth/register_user.dart';
import 'domain/usecases/auth/restore_session.dart';
import 'domain/usecases/auth/sign_in_with_google.dart';
import 'firebase_options.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/views/auth/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ftpDatasource = kIsWeb ? FakeFtpDatasource() : FtpRealDatasource();
    debugPrint('HOTFTP: Initializing with ${ftpDatasource.runtimeType}');
    final ftpRepository = FtpRepositoryImpl(ftpDatasource);

    final authRepository = FirebaseAuthRepositoryImpl(
      FirebaseAuthDatasource(),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            loginUser: LoginUser(authRepository),
            registerUser: RegisterUser(authRepository),
            signInWithGoogle: SignInWithGoogle(authRepository),
            logoutUser: LogoutUser(authRepository),
            restoreSession: RestoreSession(authRepository),
            observeAuthState: ObserveAuthState(authRepository),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HOTFTP',
        theme: AppTheme.dark,
        home: AuthGate(ftpRepository: ftpRepository),
      ),
    );
  }
}
