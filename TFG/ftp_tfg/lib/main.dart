import 'package:flutter/material.dart';
import 'package:ftp_tfg/data/repositories/ftp_repository.dart';
import 'data/datasources/fake_datasource.dart';
import 'domain/usecases/get_remote_files.dart';
import 'presentation/viewmodels/ftp_viewmodel.dart';
import 'presentation/views/ftp_screen.dart';
import 'package:provider/provider.dart';

void main() {
  final datasource = FakeFtpDatasource(); 
//final datasource = FtpDatasourceImpl(); ← cuando esté listo
  final repository = FtpRepositoryImpl(datasource);
  final getRemoteFiles = GetRemoteFiles(repository);

  runApp(
    ChangeNotifierProvider(
      create: (_) => FtpViewModel(getRemoteFiles)..loadFiles("/"),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FTP TFG',
      home: FtpScreen(),
    );
  }
}
