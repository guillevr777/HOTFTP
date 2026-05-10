import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/interfaces/i_link_email_password_use_case.dart';
import '../../domain/interfaces/i_login_user_use_case.dart';
import '../../domain/interfaces/i_logout_user_use_case.dart';
import '../../domain/interfaces/i_observe_auth_state_use_case.dart';
import '../../domain/interfaces/i_register_user_use_case.dart';
import '../../domain/interfaces/i_request_password_reset_use_case.dart';
import '../../domain/interfaces/i_restore_session_use_case.dart';
import '../../domain/interfaces/i_sign_in_with_google_use_case.dart';
import '../../domain/interfaces/i_update_display_name_use_case.dart';

class AuthViewModel extends ChangeNotifier {
  final ILoginUserUseCase loginUser;
  final IRegisterUserUseCase registerUser;
  final ISignInWithGoogleUseCase signInWithGoogle;
  final ILogoutUserUseCase logoutUser;
  final IRestoreSessionUseCase restoreSession;
  final IObserveAuthStateUseCase observeAuthState;
  final ILinkEmailPasswordUseCase linkEmailPassword;
  final IRequestPasswordResetUseCase requestPasswordReset;
  final IUpdateDisplayNameUseCase updateDisplayName;

  AuthViewModel({
    required this.loginUser,
    required this.registerUser,
    required this.signInWithGoogle,
    required this.logoutUser,
    required this.restoreSession,
    required this.observeAuthState,
    required this.linkEmailPassword,
    required this.requestPasswordReset,
    required this.updateDisplayName,
  });

  AppUser? currentUser;
  bool isLoading = false;
  bool isBootstrapping = true;
  String? error;
  StreamSubscription<AppUser?>? _subscription;

  Future<void> initialize() async {
    isBootstrapping = true;
    notifyListeners();

    currentUser = await restoreSession.execute();

    _subscription?.cancel();
    _subscription = observeAuthState.execute().listen((user) {
      currentUser = user;
      notifyListeners();
    });

    isBootstrapping = false;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      currentUser = await loginUser.execute(email: email, password: password);
      return true;
    } catch (e) {
      error = _readableMessage(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String displayName,
    required String password,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      currentUser = await registerUser.execute(
        email: email,
        displayName: displayName,
        password: password,
      );
      return true;
    } catch (e) {
      error = _readableMessage(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      currentUser = await signInWithGoogle.execute();
      return true;
    } catch (e) {
      error = _readableMessage(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isLoading = true;
    notifyListeners();
    await logoutUser.execute();
    currentUser = null;
    isLoading = false;
    notifyListeners();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await requestPasswordReset.execute(email);
      return true;
    } catch (e) {
      error = _readableMessage(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changeDisplayName(String displayName) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      currentUser = await updateDisplayName.execute(displayName);
      return true;
    } catch (e) {
      error = _readableMessage(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> linkPasswordAccess(String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      currentUser = await linkEmailPassword.execute(password);
      return true;
    } catch (e) {
      error = _readableMessage(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _readableMessage(Object error) {
    if (error is Exception) {
      final message = error.toString().replaceFirst('Exception: ', '');
      if (message.startsWith('FirebaseAuthException')) {
        final details = message.split('] ').last;
        switch (details) {
          case 'provider-already-linked':
            return 'La cuenta ya tiene este mÃ©todo de acceso vinculado.';
          case 'missing-email':
            return 'La cuenta actual no tiene un correo vÃ¡lido para enlazar.';
          case 'credential-already-in-use':
            return 'Ese correo ya pertenece a otra cuenta.';
          case 'email-already-in-use':
            return 'Ese correo ya estÃ¡ registrado.';
          case 'invalid-email':
            return 'El correo no tiene un formato vÃ¡lido.';
          case 'weak-password':
            return 'La contraseÃ±a es demasiado dÃ©bil.';
          case 'requires-recent-login':
            return 'Vuelve a iniciar sesiÃ³n para completar esta acciÃ³n.';
          case 'no-password-provider-linked':
            return 'Esta cuenta usa Google y aÃºn no tiene una contraseÃ±a vinculada.';
          case 'user-not-found':
            return 'No existe ninguna cuenta asociada a ese correo.';
          case 'network-request-failed':
            return 'No se pudo comprobar el acceso de la cuenta. Revisa la conexiÃ³n e intÃ©ntalo de nuevo.';
          default:
            return details;
        }
      }
      return message;
    }
    return error.toString();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}




