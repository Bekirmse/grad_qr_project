import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. KAYIT
  Future<String?> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    String role = 'user',
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Veritabanına kayıt
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': role,
        'isVerified': false, // <--- EKLENDİ: Başlangıçta doğrulanmamış olsun
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Bir hata oluştu: $e";
    }
  }

  // 2. GİRİŞ KONTROLÜ
  Future<String?> checkCredentials(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 3. E-POSTADAN TELEFON BULMA
  Future<String?> getPhoneByEmail(String email) async {
    try {
      var snapshot =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.get('phoneNumber');
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 4. SMS GÖNDERME
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
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // 5. KOD DOĞRULAMA VE GİRİŞ (GÜNCELLENDİ)
  Future<String?> verifyOtpAndLogin({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential? userCredential;

      // Kullanıcı zaten email ile oturum açmış durumda mı? (LoginPage'deki akışa göre evet)
      if (_auth.currentUser != null) {
        userCredential = await _auth.currentUser!.linkWithCredential(
          credential,
        );
      } else {
        userCredential = await _auth.signInWithCredential(credential);
      }

      // --- EKLENDİ: DOĞRULAMA BAŞARILI OLUNCA 'isVerified' TRUE YAPILMALI ---
      if (userCredential.user != null) {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({'isVerified': true});
      }
      // -----------------------------------------------------------------------

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-linked' ||
          e.code == 'provider-already-linked' ||
          e.code == 'ERROR_PROVIDER_ALREADY_LINKED') {
        // Zaten linklenmişse bile garanti olsun diye true yapalım
        if (_auth.currentUser != null) {
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .update({'isVerified': true});
        }
        return null;
      }
      return e.message;
    }
  }

  // 6. ŞİFRE GÜNCELLEME
  Future<String?> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 7. ROL ÖĞRENME
  Future<String> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Önce Firestore'dan çekmeye çalışalım
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        return data?['role'] ?? 'user';
      }
    }
    return 'user';
  }

  // 8. ÇIKIŞ YAPMA
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
