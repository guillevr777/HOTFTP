import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/ftp_profile.dart';
import '../viewmodels/ftp_viewmodel.dart';

class FtpScreen extends StatefulWidget {
  const FtpScreen({super.key});

  @override
  State<FtpScreen> createState() => _FtpScreenState();
}

class _FtpScreenState extends State<FtpScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: "21");
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FtpViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("FTP Client")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔌 FORMULARIO DE CONEXIÓN
            if (!vm.isConnected) ...[
              TextField(
                controller: _hostController,
                decoration: const InputDecoration(labelText: "Servidor FTP"),
              ),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Puerto"),
              ),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(labelText: "Usuario"),
              ),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Contraseña"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: vm.isLoading
                    ? null
                    : () async {
                        final profile = FtpProfile(
                          host: _hostController.text,
                          port: int.tryParse(_portController.text) ?? 21,
                          username: _userController.text,
                          password: _passController.text,
                        );

                        await vm.connect(profile);

                        if (vm.isConnected) {
                          vm.loadFiles("/");
                        }
                      },
                child: const Text("Conectar"),
              ),
            ],

            // ⏳ CARGANDO
            if (vm.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),

            // 📂 LISTADO DE ARCHIVOS
            if (vm.isConnected && !vm.isLoading)
              Expanded(
                child: ListView.builder(
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
                      onTap: file.isDirectory
                          ? () => vm.loadFiles(file.path)
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
