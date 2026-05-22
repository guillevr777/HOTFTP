import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_io/io.dart';

class AndroidStorageAccess {
  const AndroidStorageAccess._();

  static Future<bool> ensureSharedStorageAccess({
    bool openSettingsIfDenied = true,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final manageStatus = await Permission.manageExternalStorage.status;
      if (manageStatus.isGranted) return true;

      final requestStatus = await Permission.manageExternalStorage.request();
      if (requestStatus.isGranted) return true;

      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return true;

      final fallbackRequest = await Permission.storage.request();
      if (fallbackRequest.isGranted) return true;

      if (openSettingsIfDenied) {
        await openAppSettings();
      }
      return false;
    } on MissingPluginException catch (e) {
      debugPrint('HOTFTP: permission plugin not registered yet -> $e');
      return false;
    }
  }

  static Future<bool> ensureScheduledDumpAccess() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final hasStorage = await ensureSharedStorageAccess();
    if (!hasStorage) return false;

    try {
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (batteryStatus.isGranted) return true;

      final requestStatus = await Permission.ignoreBatteryOptimizations
          .request();
      return requestStatus.isGranted || requestStatus.isLimited;
    } on MissingPluginException catch (e) {
      debugPrint('HOTFTP: battery optimization permission unavailable -> $e');
      return true;
    }
  }
}
