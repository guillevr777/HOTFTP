import 'package:flutter/material.dart';
import 'package:ftp_tfg/data/datasources/fake_datasource.dart';
import 'package:ftp_tfg/data/repositories/ftp_repository.dart';
import 'package:provider/provider.dart';

import 'domain/usecases/get_remote_files.dart';
import 'presentation/viewmodels/ftp_viewmodel.dart';
import 'presentation/views/ftp_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Datasource FAKE (puedes cambiarlo por el real cuando quieras)
  final datasource = FakeFtpDatasource();

  // Repository
  final repository = FtpRepositoryImpl(datasource);

  // Use case
  final getRemoteFiles = GetRemoteFiles(repository);

  runApp(
    ChangeNotifierProvider(
      create: (_) => FtpViewModel(
        getRemoteFiles: getRemoteFiles,
      ),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FTP Client TFG',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const FtpScreen(),
    );
  }
}
