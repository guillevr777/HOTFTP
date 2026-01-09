import 'package:flutter/material.dart';
import 'package:ftp_tfg/presentation/viewmodels/ftp_viewmodel.dart';

class FtpScreen extends StatefulWidget {
  final FtpViewModel vm;

  const FtpScreen({super.key, required this.vm});

  @override
  State<FtpScreen> createState() => _FtpScreenState();
}

class _FtpScreenState extends State<FtpScreen> {
  @override
  void initState() {
    super.initState();
    widget.vm.loadFiles("/");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FTP")),
      body: ListView.builder(
        itemCount: widget.vm.remoteFiles.length,
        itemBuilder: (_, i) =>
            Text(widget.vm.remoteFiles[i].name),
      ),
    );
  }
}
