import 'package:firebase_core/firebase_core.dart';
import 'package:projects/firebase_options.dart';
import 'package:projects/services/auth/auth_user.dart';
import 'package:projects/services/auth/auth_exceptions.dart';
import 'package:projects/services/auth/auth_provider.dart';

import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, FirebaseAuthException;

class FirebaseAuthProvider implements AuthProvider {
  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        return AuthUser.fromFirebase(user);
      } else {
        throw UserNotLoggedInAuthExceptions();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw WeakPasswordAuthExceptions();
      } else if (e.code == 'email-already-in-use') {
        throw EmailAlreadyInUseAuthExceptions();
      } else if (e.code == 'invalid-email') {
        throw InvalidEmailAuthExceptions();
      } else {
        throw GenericAuthExceptions();
      }
    } catch (_) {
      throw GenericAuthExceptions();
    }
  }

  @override
  // TODO: implement currentUser
  AuthUser? get currentUser {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return AuthUser.fromFirebase(user);
    } else {
      return null;
    }
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Ensure we have the freshest verification status
      await FirebaseAuth.instance.currentUser?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser ?? credential.user;
      if (refreshedUser != null) {
        return AuthUser.fromFirebase(refreshedUser);
      } else {
        throw UserNotLoggedInAuthExceptions();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw UserNotFoundAuthException();
      } else if (e.code == 'wrong-password') {
        throw WrongPasswordAuthExceptions();
      } else {
        throw GenericAuthExceptions();
      }
    } catch (_) {
      throw GenericAuthExceptions();
    }
  }

  @override
  Future<void> logOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseAuth.instance.signOut();
    } else {
      throw UserNotLoggedInAuthExceptions();
    }
  }

  @override
  Future<void> sendEmailVeritication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    } else {
      throw UserNotLoggedInAuthExceptions();
    }
  }

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Refresh current user on app start to pick up verification status
    await FirebaseAuth.instance.currentUser?.reload();
  }

  @override
  Future<void> sendPasswordReset({required String toEmail}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: toEmail);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw InvalidEmailAuthExceptions();
        case 'user-not-found':
          throw UserNotFoundAuthException();
        default:
          throw GenericAuthExceptions();
      }
    } catch (_) {
      throw GenericAuthExceptions();
    }
  }
}
