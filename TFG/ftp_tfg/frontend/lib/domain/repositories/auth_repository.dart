import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<AppUser?> currentUser();
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });
  Future<AppUser> signInWithGoogle();
  Future<AppUser> linkEmailPassword(String password);
  Future<AppUser> updateDisplayName(String displayName);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
}



