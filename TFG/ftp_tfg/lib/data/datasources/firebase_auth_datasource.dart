import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/app_user.dart';
import '../../firebase_options.dart';

class FirebaseAuthDatasource {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;
  Future<void>? _initializingGoogle;

  FirebaseAuthDatasource({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

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
      email: email.trim(),
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
      email: email.trim(),
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
        message: 'La cuenta ya tiene acceso con correo y contraseÃ±a',
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
        message: 'No se pudo vincular el acceso con correo y contraseÃ±a',
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
        message: 'El nombre no puede estar vacÃ­o',
      );
    }
    await user.updateDisplayName(trimmed);
    await user.reload();
    return _mapUser(_auth.currentUser) ?? _mapUser(user)!;
  }

  Future<void> sendPasswordResetEmail(String email) {
    final trimmed = email.trim();
    return _sendPasswordResetEmail(trimmed);
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    final methods = await _fetchSignInMethodsForEmail(email);
    if (methods.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No se ha encontrado ninguna cuenta asociada a ese correo',
      );
    }
    if (!methods.contains('password')) {
      throw FirebaseAuthException(
        code: 'no-password-provider-linked',
        message:
            'Esta cuenta se inicia con Google y todavÃ­a no tiene una contraseÃ±a vinculada.',
      );
    }
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<List<String>> _fetchSignInMethodsForEmail(String email) async {
    final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
    final response = await http.post(
      Uri.https(
        'identitytoolkit.googleapis.com',
        '/v1/accounts:createAuthUri',
        {'key': apiKey},
      ),
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'identifier': email,
        'continueUri': 'http://localhost',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FirebaseAuthException(
        code: 'network-request-failed',
        message: 'No se pudo comprobar los mÃ©todos de inicio de sesiÃ³n',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final methods = <String>[];
    for (final key in ['allProviders', 'signinMethods']) {
      final raw = body[key];
      if (raw is List) {
        methods.addAll(raw.map((value) => value.toString()));
      }
    }
    return methods.toSet().toList(growable: false);
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), if (!kIsWeb) _googleSignIn.signOut()]);
  }
}



