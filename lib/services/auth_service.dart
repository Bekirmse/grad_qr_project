import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registerAdmin({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return registerUser(
      fullName: fullName,
      email: email,
      password: password,
      role: 'admin',
    );
  }

  Future<String?> registerUser({
    required String fullName,
    required String email,
    required String password,
    String role = 'user',
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'fullName': fullName,
        'email': email,
        'role': role,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (_) {
      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  Future<String?> checkCredentials(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    }
  }

  static String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'email-already-in-use':
        return 'This email address is already in use.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'operation-not-allowed':
        return 'This sign-in method is not supported.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> getPhoneByEmail(String email) async {
    try {
      final snap = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return snap.docs.first.get('phoneNumber');
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> startPhoneAuth({
    required String phoneNumber,
    required Function(String, int?) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
          } catch (e) {
            debugPrint('Error signing in with phone credential: $e');
            onVerificationFailed(FirebaseAuthException(
              code: 'sign-in-failed',
              message: 'Error signing in: $e',
            ));
          }
        },
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      debugPrint('Error starting phone authentication: $e');
      onVerificationFailed(FirebaseAuthException(
        code: 'verification-error',
        message: 'Error verifying phone: $e',
      ));
    }
  }

  Future<String?> verifyOtpAndLogin({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential? userCredential;
      if (_auth.currentUser != null) {
        userCredential = await _auth.currentUser!.linkWithCredential(credential);
      } else {
        userCredential = await _auth.signInWithCredential(credential);
      }
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).update({'isVerified': true});
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-linked' || e.code == 'provider-already-linked') {
        if (_auth.currentUser != null) {
          await _firestore.collection('users').doc(_auth.currentUser!.uid).update({'isVerified': true});
        }
        return null;
      }
      return e.message;
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc.data()?['role'] ?? 'user';
        }
      }
      return 'user';
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return 'user';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      debugPrint('Error sending email verification: $e');
      rethrow;
    }
  }

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      debugPrint('Error reloading user: $e');
    }
  }

  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  String? currentUserId() {
    return _auth.currentUser?.uid;
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return 'Google sign in cancelled';

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'fullName': user.displayName ?? googleUser.displayName ?? 'User',
            'email': user.email ?? '',
            'role': 'user',
            'isVerified': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          final existingName = userDoc.data()?['fullName']?.toString() ?? '';
          final newName = user.displayName ?? googleUser.displayName ?? '';
          if (existingName.isEmpty || existingName == 'User') {
            if (newName.isNotEmpty) {
              await _firestore.collection('users').doc(user.uid).update({'fullName': newName});
            }
          }
        }
      }
      return null;
    } catch (e) {
      return 'Google sign in error: $e';
    }
  }

  Future<String?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user != null) {
        final appleFullName = [
          credential.givenName ?? '',
          credential.familyName ?? '',
        ].where((s) => s.isNotEmpty).join(' ');

        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'fullName': appleFullName.isNotEmpty ? appleFullName : (user.displayName ?? 'User'),
            'email': user.email ?? credential.email ?? '',
            'role': 'user',
            'isVerified': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          final existingName = userDoc.data()?['fullName']?.toString() ?? '';
          final newName = appleFullName.isNotEmpty ? appleFullName : (user.displayName ?? '');
          if ((existingName.isEmpty || existingName == 'User') && newName.isNotEmpty) {
            await _firestore.collection('users').doc(user.uid).update({'fullName': newName});
          }
        }
      }
      return null;
    } catch (e) {
      return 'Apple sign in error: $e';
    }
  }
}
