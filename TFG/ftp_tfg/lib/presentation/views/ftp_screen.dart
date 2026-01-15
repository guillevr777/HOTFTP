import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/ftp_viewmodel.dart';

class FtpScreen extends StatelessWidget {
  const FtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FtpViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("FTP")),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: vm.remoteFiles.length,
              itemBuilder: (_, i) {
                final file = vm.remoteFiles[i];
                return ListTile(
                  leading: Icon(
                    file.isDirectory
                        ? Icons.folder
                        : Icons.insert_drive_file,
                  ),
                  title: Text(file.name),
                  onTap: () {
                    if (file.isDirectory) {
                      vm.loadFiles(file.path);
                    }
                  },
                );
              },
            ),
    );
  }
}
