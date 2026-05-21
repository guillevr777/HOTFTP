import 'package:flutter/material.dart';

import '../../domain/entities/ftp_profile.dart';
import '../../domain/interfaces/i_delete_profile_use_case.dart';
import '../../domain/interfaces/i_get_profiles_use_case.dart';
import '../../domain/interfaces/i_save_profile_use_case.dart';
import '../../domain/interfaces/i_test_connection_use_case.dart';

class ProfileViewModel extends ChangeNotifier {
  final IGetProfilesUseCase _getProfiles;
  final ISaveProfileUseCase _saveProfile;
  final IDeleteProfileUseCase _deleteProfile;
  final ITestConnectionUseCase _testConnectionUseCase;
  final String ownerId;

  ProfileViewModel({
    required IGetProfilesUseCase getProfiles,
    required ISaveProfileUseCase saveProfile,
    required IDeleteProfileUseCase deleteProfile,
    required ITestConnectionUseCase testConnectionUseCase,
    required this.ownerId,
  })  : _getProfiles = getProfiles,
        _saveProfile = saveProfile,
        _deleteProfile = deleteProfile,
        _testConnectionUseCase = testConnectionUseCase;

  List<FtpProfile> profiles = [];
  bool isLoading = false;
  bool isTesting = false;
  String? testResult;

  Future<void> loadProfiles() async {
    isLoading = true;
    notifyListeners();
    profiles = await _getProfiles.execute(ownerId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> saveProfile(FtpProfile profile) async {
    await _saveProfile.execute(profile, ownerId);
    await loadProfiles();
  }

  Future<void> deleteProfile(FtpProfile profile) async {
    await _deleteProfile.execute(profile, ownerId);
    await loadProfiles();
  }

  Future<bool> testConnection(FtpProfile profile) async {
    isTesting = true;
    testResult = null;
    notifyListeners();
    bool ok = false;
    try {
      ok = await _testConnectionUseCase.execute(profile);
    } catch (_) {
      ok = false;
    }
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




