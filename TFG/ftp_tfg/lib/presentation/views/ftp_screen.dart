import 'package:flutter/material.dart';
import '../viewmodels/ftp_viewmodel.dart';

class FtpScreen extends StatefulWidget {
  final FtpViewModel vm;

  const FtpScreen({super.key, required this.vm});

  @override
  State<FtpScreen> createState() => _FtpScreenState();
}

class _FtpScreenState extends State<FtpScreen> {
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    await widget.vm.loadFiles("/"); // carga archivos fake
    setState(() {
      loading = false; // reconstruye la UI
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FTP")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: widget.vm.remoteFiles.length,
              itemBuilder: (_, index) {
                final file = widget.vm.remoteFiles[index];
                return ListTile(
                  leading: Icon(
                    file['isDirectory'] ? Icons.folder : Icons.insert_drive_file,
                  ),
                  title: Text(file['name']),
                  subtitle: file['isDirectory']
                      ? const Text("Carpeta")
                      : Text("${file['size']} bytes"),
                );
              },
            ),
    );
  }
}
