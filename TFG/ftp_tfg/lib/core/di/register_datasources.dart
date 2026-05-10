import 'package:flutter/foundation.dart';

import '../../data/datasources/fake_datasource.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/datasources/ftp_real_datasource.dart';
import '../../data/interfaces/ftp_datasource.dart';

class AppDataSources {
  final FtpDatasource ftpDatasource;
  final FirebaseAuthDatasource firebaseAuthDatasource;

  AppDataSources({
    required this.ftpDatasource,
    required this.firebaseAuthDatasource,
  });
}

AppDataSources createDataSources() {
  const useFakeFtp = bool.fromEnvironment('HOTFTP_USE_FAKE_FTP');
  final ftpDatasource =
      kIsWeb || useFakeFtp ? FakeFtpDatasource() : FtpRealDatasource();
  debugPrint('HOTFTP: Initializing with ${ftpDatasource.runtimeType}');

  return AppDataSources(
    ftpDatasource: ftpDatasource,
    firebaseAuthDatasource: FirebaseAuthDatasource(),
  );
}
