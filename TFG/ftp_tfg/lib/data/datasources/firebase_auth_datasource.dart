import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/app_user.dart';
import '../../firebase_options.dart';

class FirebaseAuthDatasource {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;
  Future<void>? _initializingGoogle;

  FirebaseAuthDatasource({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance {
    // Make auth emails use the app language when possible.
    // If the locale is unavailable, Firebase falls back to its default language.
    final locale = ui.PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode.trim();
    if (languageCode.isNotEmpty) {
      _auth.setLanguageCode(languageCode);
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    // Android's Credential Manager flow needs the web client ID from Firebase.
    _initializingGoogle ??= _googleSignIn.initialize(
      serverClientId: DefaultFirebaseOptions.googleWebClientId,
    );
    await _initializingGoogle;
    _googleInitialized = true;
  }

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : (user.email ?? 'Usuario'),
      photoUrl: user.photoURL,
      providers: user.providerData
          .map((provider) => provider.providerId)
          .where((providerId) => providerId.trim().isNotEmpty)
          .toSet()
          .toList(growable: false),
    );
  }

  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(_mapUser);
  }

  Future<AppUser?> currentUser() async {
    return _mapUser(_auth.currentUser);
  }

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: _normalizeEmail(email),
      password: password,
    );
    final user = _mapUser(credential.user);
    if (user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'No se pudo obtener el usuario autenticado',
      );
    }
    return user;
  }

  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: _normalizeEmail(email),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'No se pudo crear el usuario',
      );
    }
    await user.updateDisplayName(displayName.trim());
    await user.reload();
    return _mapUser(_auth.currentUser) ?? _mapUser(user)!;
  }

  Future<AppUser> signInWithGoogle() async {
    final UserCredential userCredential;
    if (kIsWeb) {
      userCredential = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      await _ensureGoogleInitialized();
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      userCredential = await _auth.signInWithCredential(credential);
    }
    final user = _mapUser(userCredential.user);
    if (user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'No se pudo obtener el usuario de Google',
      );
    }
    return user;
  }

  Future<AppUser> linkEmailPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No hay un usuario autenticado',
      );
    }

    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'La cuenta actual no tiene un correo asociado',
      );
    }

    final hasPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    if (hasPasswordProvider) {
      throw FirebaseAuthException(
        code: 'provider-already-linked',
        message: 'La cuenta ya tiene acceso con correo y contrasena',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    final linkedCredential = await user.linkWithCredential(credential);
    final linkedUser = _mapUser(linkedCredential.user);
    if (linkedUser == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'No se pudo vincular el acceso con correo y contrasena',
      );
    }
    return linkedUser;
  }

  Future<AppUser> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No hay un usuario autenticado',
      );
    }
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-display-name',
        message: 'El nombre no puede estar vacio',
      );
    }
    await user.updateDisplayName(trimmed);
    await user.reload();
    return _mapUser(_auth.currentUser) ?? _mapUser(user)!;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _sendPasswordResetEmail(_normalizeEmail(email));
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), if (!kIsWeb) _googleSignIn.signOut()]);
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();
}
