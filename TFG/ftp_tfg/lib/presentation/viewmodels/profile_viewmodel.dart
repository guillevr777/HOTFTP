import 'package:flutter/material.dart';
import '../../domain/entities/ftp_profile.dart';
import '../../domain/repositories/ftp_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final FtpRepository repository;

  ProfileViewModel({required this.repository});

  List<FtpProfile> profiles = [];
  bool isLoading = false;
  bool isTesting = false;
  String? testResult;

  Future<void> loadProfiles() async {
    isLoading = true;
    notifyListeners();
    profiles = await repository.getProfiles();
    isLoading = false;
    notifyListeners();
  }

  Future<void> saveProfile(FtpProfile profile) async {
    await repository.saveProfile(profile);
    await loadProfiles();
  }

  Future<void> deleteProfile(int id) async {
    await repository.deleteProfile(id);
    await loadProfiles();
  }

  Future<bool> testConnection(FtpProfile profile) async {
    isTesting = true;
    testResult = null;
    notifyListeners();
    final ok = await repository.testConnection(profile);
    testResult = ok ? 'Conexion exitosa' : 'No se pudo conectar';
    isTesting = false;
    notifyListeners();
    return ok;
  }

  void clearTestResult() {
    testResult = null;
    notifyListeners();
  }
}
