import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/usecases/auth/login_user.dart';
import '../../domain/usecases/auth/logout_user.dart';
import '../../domain/usecases/auth/observe_auth_state.dart';
import '../../domain/usecases/auth/register_user.dart';
import '../../domain/usecases/auth/restore_session.dart';
import '../../domain/usecases/auth/sign_in_with_google.dart';

class AuthViewModel extends ChangeNotifier {
  final LoginUser loginUser;
  final RegisterUser registerUser;
  final SignInWithGoogle signInWithGoogle;
  final LogoutUser logoutUser;
  final RestoreSession restoreSession;
  final ObserveAuthState observeAuthState;

  AuthViewModel({
    required this.loginUser,
    required this.registerUser,
    required this.signInWithGoogle,
    required this.logoutUser,
    required this.restoreSession,
    required this.observeAuthState,
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

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      currentUser = await loginUser.execute(
        email: email,
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

  String _readableMessage(Object error) {
    if (error is Exception) {
      final message = error.toString().replaceFirst('Exception: ', '');
      if (message.startsWith('FirebaseAuthException')) {
        return message.split('] ').last;
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
