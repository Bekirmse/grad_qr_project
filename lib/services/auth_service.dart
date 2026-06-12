import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    String role = 'user',
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': role,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  Future<String?> checkCredentials(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
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
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
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
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['role'] ?? 'user';
      }
    }
    return 'user';
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
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
            'fullName': user.displayName ?? 'User',
            'email': user.email ?? '',
            'phoneNumber': '',
            'role': 'user',
            'isVerified': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
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
        scopes: [],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'fullName': user.displayName ?? 'User',
            'email': user.email ?? '',
            'phoneNumber': '',
            'role': 'user',
            'isVerified': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return null;
    } catch (e) {
      return 'Apple sign in error: $e';
    }
  }
}
