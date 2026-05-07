import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/usecases/auth/login_user.dart';
import '../../domain/usecases/auth/logout_user.dart';
import '../../domain/usecases/auth/observe_auth_state.dart';
import '../../domain/usecases/auth/link_email_password.dart';
import '../../domain/usecases/auth/request_password_reset.dart';
import '../../domain/usecases/auth/register_user.dart';
import '../../domain/usecases/auth/restore_session.dart';
import '../../domain/usecases/auth/sign_in_with_google.dart';
import '../../domain/usecases/auth/update_display_name.dart';

class AuthViewModel extends ChangeNotifier {
  final LoginUser loginUser;
  final RegisterUser registerUser;
  final SignInWithGoogle signInWithGoogle;
  final LogoutUser logoutUser;
  final RestoreSession restoreSession;
  final ObserveAuthState observeAuthState;
  final LinkEmailPassword linkEmailPassword;
  final RequestPasswordReset requestPasswordReset;
  final UpdateDisplayName updateDisplayName;

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
            return 'La cuenta ya tiene este método de acceso vinculado.';
          case 'missing-email':
            return 'La cuenta actual no tiene un correo válido para enlazar.';
          case 'credential-already-in-use':
            return 'Ese correo ya pertenece a otra cuenta.';
          case 'email-already-in-use':
            return 'Ese correo ya está registrado.';
          case 'invalid-email':
            return 'El correo no tiene un formato válido.';
          case 'weak-password':
            return 'La contraseña es demasiado débil.';
          case 'requires-recent-login':
            return 'Vuelve a iniciar sesión para completar esta acción.';
          case 'no-password-provider-linked':
            return 'Esta cuenta usa Google y aún no tiene una contraseña vinculada.';
          case 'user-not-found':
            return 'No existe ninguna cuenta asociada a ese correo.';
          case 'network-request-failed':
            return 'No se pudo comprobar el acceso de la cuenta. Revisa la conexión e inténtalo de nuevo.';
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
