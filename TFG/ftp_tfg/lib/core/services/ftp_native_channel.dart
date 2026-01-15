import 'dart:async';
import 'package:flutter/services.dart';

class FtpNativeChannel {
  static const _channel = MethodChannel('ftp_native_channel');

  /// Conectar al servidor FTP
  Future<bool> connect(Map<String, dynamic> profile) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'connect',
        {
          "host": profile["host"],
          "port": profile["port"],
          "username": profile["username"],
          "password": profile["password"],
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print("Error conectando al FTP: ${e.message}");
      return false;
    }
  }

  /// Listar archivos remotos en un path
  Future<List<Map<String, dynamic>>> listRemoteFiles(String path) async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'listRemoteFiles',
        {"path": path},
      );

      // Convertir List<dynamic> a List<Map<String,dynamic>>
      return (result ?? []).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        // Asegúrate que tenga todos los campos
        return {
          "name": map["name"] ?? "",
          "size": map["size"] ?? 0,
          "isDir": map["isDir"] ?? false,
        };
      }).toList();
    } on PlatformException catch (e) {
      print("Error listando archivos: ${e.message}");
      return [];
    }
  }

  /// Subir archivo al servidor
  Future<bool> uploadFile(String localPath, String remotePath) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'uploadFile',
        {
          "localPath": localPath,
          "remotePath": remotePath,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print("Error subiendo archivo: ${e.message}");
      return false;
    }
  }

  /// Descargar archivo desde el servidor
  Future<bool> downloadFile(String remoteFile, String localPath) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'downloadFile',
        {
          "remoteFile": remoteFile,
          "localPath": localPath,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print("Error descargando archivo: ${e.message}");
      return false;
    }
  }
}
