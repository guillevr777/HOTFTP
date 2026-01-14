import 'package:flutter/material.dart';
import 'package:ftp_tfg/presentation/viewmodels/ftp_viewmodel.dart';
import 'presentation/views/ftp_screen.dart';
import 'data/datasources/fake_datasource.dart';

void main() {
  // Datasource fake (para probar UI)
  final datasource = FakeFtpDatasource();

  // ViewModel
  final viewModel = FtpViewModel(datasource);

  runApp(MyApp(viewModel: viewModel));
}

class MyApp extends StatelessWidget {
  final FtpViewModel viewModel;

  const MyApp({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FTP TFG',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: FtpScreen(vm: viewModel),
    );
  }
}
