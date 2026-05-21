import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource datasource;

  FirebaseAuthRepositoryImpl(this.datasource);

  @override
  Stream<AppUser?> authStateChanges() => datasource.authStateChanges();

  @override
  Future<AppUser?> currentUser() => datasource.currentUser();

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => datasource.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) => datasource.registerWithEmailAndPassword(
    email: email,
    password: password,
    displayName: displayName,
  );

  @override
  Future<AppUser> signInWithGoogle() => datasource.signInWithGoogle();

  @override
  Future<AppUser> linkEmailPassword(String password) =>
      datasource.linkEmailPassword(password);

  @override
  Future<AppUser> updateDisplayName(String displayName) =>
      datasource.updateDisplayName(displayName);

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      datasource.sendPasswordResetEmail(email);

  @override
  Future<void> signOut() => datasource.signOut();
}



