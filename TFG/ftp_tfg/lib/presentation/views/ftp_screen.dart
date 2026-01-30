import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/ftp_viewmodel.dart';

class FtpScreen extends StatefulWidget {
  const FtpScreen({super.key});

  @override
  State<FtpScreen> createState() => _FtpScreenState();
}

class _FtpScreenState extends State<FtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '21');
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FtpViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cliente FTP TFG')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // FORMULARIO DE CONEXIÓN
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _hostController,
                    decoration: const InputDecoration(labelText: 'IP / Host'),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: _portController,
                    decoration: const InputDecoration(labelText: 'Puerto'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: _userController,
                    decoration: const InputDecoration(labelText: 'Usuario'),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: _passController,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await vm.loadFiles('/');(
                          host: _hostController.text,
                          port: int.tryParse(_portController.text) ?? 21,
                          username: _userController.text,
                          password: _passController.text,
                        );
                      }
                    },
                    child: const Text('Conectar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (vm.isLoading) const CircularProgressIndicator(),
            // LISTA DE ARCHIVOS REMOTOS
            Expanded(
              child: ListView(
                children: vm.remoteFiles.map((f) => ListTile(
                  leading: Icon(f.isDirectory ? Icons.folder : Icons.insert_drive_file),
                  title: Text(f.name),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
