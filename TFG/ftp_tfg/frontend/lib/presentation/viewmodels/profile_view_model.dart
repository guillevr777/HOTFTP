import 'package:flutter/material.dart';

import '../../domain/entities/ftp_profile.dart';
import '../../domain/interfaces/i_delete_profile_use_case.dart';
import '../../domain/interfaces/i_get_profiles_use_case.dart';
import '../../domain/interfaces/i_record_event_use_case.dart';
import '../../domain/interfaces/i_save_profile_use_case.dart';
import '../../domain/interfaces/i_test_connection_use_case.dart';
import '../../domain/entities/system_event.dart';

class ProfileViewModel extends ChangeNotifier {
  final IGetProfilesUseCase _getProfiles;
  final ISaveProfileUseCase _saveProfile;
  final IDeleteProfileUseCase _deleteProfile;
  final ITestConnectionUseCase _testConnectionUseCase;
  final IRecordEventUseCase _recordEvent;
  final String ownerId;

  ProfileViewModel({
    required IGetProfilesUseCase getProfiles,
    required ISaveProfileUseCase saveProfile,
    required IDeleteProfileUseCase deleteProfile,
    required ITestConnectionUseCase testConnectionUseCase,
    required IRecordEventUseCase recordEvent,
    required this.ownerId,
  })  : _getProfiles = getProfiles,
        _saveProfile = saveProfile,
        _deleteProfile = deleteProfile,
        _testConnectionUseCase = testConnectionUseCase,
        _recordEvent = recordEvent;

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
    final isNew = profile.id == null;
    final savedId = await _saveProfile.execute(profile, ownerId);
    await _trackEvent(
      eventType: isNew ? 'profile_created' : 'profile_updated',
      severity: SystemEventSeverity.success,
      title: isNew ? 'Conexión creada' : 'Conexión actualizada',
      message: isNew
          ? 'Se creó la conexión "${profile.name}".'
          : 'Se guardaron los cambios de la conexión "${profile.name}".',
      relatedProfileId: profile.id ?? savedId,
    );
    await loadProfiles();
  }

  Future<void> deleteProfile(FtpProfile profile) async {
    await _deleteProfile.execute(profile, ownerId);
    await _trackEvent(
      eventType: 'profile_deleted',
      severity: SystemEventSeverity.warning,
      title: 'Conexión eliminada',
      message: 'Se eliminó la conexión "${profile.name}".',
      relatedProfileId: profile.id,
    );
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
    testResult = ok ? 'Conexión exitosa' : 'No se pudo conectar';
    isTesting = false;
    notifyListeners();
    return ok;
  }

  void clearTestResult() {
    testResult = null;
    notifyListeners();
  }

  Future<void> _trackEvent({
    required String eventType,
    required SystemEventSeverity severity,
    required String title,
    required String message,
    int? relatedProfileId,
  }) async {
    try {
      await _recordEvent.execute(
        SystemEvent(
          ownerId: ownerId,
          eventType: eventType,
          severity: severity,
          title: title,
          message: message,
          relatedProfileId: relatedProfileId,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // La actividad reciente no debe bloquear la gestión de conexiones.
    }
  }
}




