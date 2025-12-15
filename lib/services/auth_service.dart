import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. KAYIT (Telefonu da kaydediyoruz)
  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    String role = 'user',
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Bir hata oluştu: $e";
    }
  }

  // 2. GİRİŞ KONTROLÜ (Sadece şifre doğru mu?)
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
        return snapshot.docs.first.get('phone');
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

  // 5. KOD DOĞRULAMA VE GİRİŞ (GÜNCELLENMİŞ VERSİYON)
  Future<String?> verifyOtpAndLogin({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Eğer kullanıcı zaten e-posta ile içerideyse (Login senaryosu)
      if (_auth.currentUser != null) {
        // Telefon numarasını hesaba bağlamayı dene
        await _auth.currentUser!.linkWithCredential(credential);
      } else {
        // Kullanıcı yoksa direkt telefonla giriş yap
        await _auth.signInWithCredential(credential);
      }
      return null; // Sorun yok, devam et
    } on FirebaseAuthException catch (e) {
      // ⚠️ İŞTE ÇÖZÜM BURASI:
      // Eğer "Bu numara zaten bağlı" (provider-already-linked) hatası gelirse,
      // bu aslında bir başarıdır. Kullanıcı doğru kodu girmiştir ve hesabı zaten onaylıdır.
      // Bu yüzden hatayı yutuyoruz ve "null" (başarılı) dönüyoruz.
      if (e.code == 'credential-already-linked' ||
          e.code == 'provider-already-linked' ||
          e.code == 'ERROR_PROVIDER_ALREADY_LINKED') {
        return null;
      }

      // Başka bir numara başka bir kullanıcıya aitse (credential-already-in-use) o gerçek hatadır.
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
      // Phone Auth ile giriş yapınca UID değişebilir, o yüzden telefondan buluyoruz
      if (user.phoneNumber != null) {
        var snapshot =
            await _firestore
                .collection('users')
                .where('phone', isEqualTo: user.phoneNumber)
                .limit(1)
                .get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.first.get('role') ?? 'user';
        }
      }
      // Yedek plan (Normal UID kontrolü)
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) return doc['role'] ?? 'user';
    }
    return 'user';
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
