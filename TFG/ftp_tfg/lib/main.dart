import 'package:flutter/material.dart';
import 'package:ftp_tfg/data/repositories/ftp_repository.dart';
import 'package:provider/provider.dart';

import 'data/datasources/fake_datasource.dart';
import 'domain/usecases/connect_ftp.dart';
import 'domain/usecases/get_remote_files.dart';
import 'domain/usecases/sync_folder.dart';
import 'presentation/viewmodels/ftp_viewmodel.dart';
import 'presentation/views/ftp_screen.dart';

void main() {
  final datasource = FakeFtpDatasource();
  final repository = FtpRepositoryImpl(datasource);

  final connectFtp = ConnectFtp(repository);
  final getRemoteFiles = GetRemoteFiles(repository);
  final syncFolder = SyncFolder(repository);

  runApp(
    ChangeNotifierProvider(
      create: (_) => FtpViewModel(
        connectFtp: connectFtp,
        getRemoteFiles: getRemoteFiles,
        syncFolder: syncFolder,
      ),
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
