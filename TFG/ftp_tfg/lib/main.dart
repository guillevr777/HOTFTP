import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import "data/datasources/fake_datasource.dart";
import "data/datasources/ftp_real_datasource.dart";
import "data/repositories/ftp_repository.dart";
import "presentation/viewmodels/profile_viewmodel.dart";
import "presentation/views/profiles/profile_list_screen.dart";
import "theme/app_theme.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    final datasource = kIsWeb ? FakeFtpDatasource() : FtpRealDatasource();
    debugPrint("HOTFTP: Initializing with ${datasource.runtimeType}");
    final repository = FtpRepositoryImpl(datasource);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel(repository: repository),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "HOTFTP",
        theme: AppTheme.dark,
        home: const ProfileListScreen(),
      ),
    );
  }
}
