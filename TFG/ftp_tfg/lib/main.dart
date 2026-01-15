import 'package:flutter/material.dart';
import 'package:ftp_tfg/data/repositories/ftp_repository.dart';
import 'package:provider/provider.dart';

import 'core/services/ftp_native_channel.dart';
import 'data/datasources/fake_datasource.dart';
// import 'data/datasources/ftp_datasource_impl.dart';

import 'domain/usecases/connect_ftp.dart';
import 'domain/usecases/get_remote_files.dart';

import 'presentation/viewmodels/ftp_viewmodel.dart';
import 'presentation/views/ftp_screen.dart';

void main() {
  // 🔁 ELIGE DATASOURCE
  final datasource = FakeFtpDatasource();
  // final datasource = FtpDatasourceImpl(FtpNativeChannel());

  final repository = FtpRepositoryImpl(datasource);

  final connectFtp = ConnectFtp(repository);
  final getRemoteFiles = GetRemoteFiles(repository);

  runApp(
    ChangeNotifierProvider(
      create: (_) => FtpViewModel(
        connectFtp: connectFtp,
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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FTP TFG',
      home: FtpScreen(),
    );
  }
}
