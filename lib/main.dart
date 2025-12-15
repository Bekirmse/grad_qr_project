import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Firebase Core paketi
import 'firebase_options.dart'; // 2. CLI ile oluşturulan ayar dosyası

import 'package:grad_qr_project/pages/admin/adminDashboard.dart';
import 'package:grad_qr_project/pages/user/homePage.dart';
import 'package:grad_qr_project/pages/user/loginPage.dart';
import 'package:grad_qr_project/pages/user/notFoundPage.dart';
import 'package:grad_qr_project/pages/user/profilePage.dart';
import 'package:grad_qr_project/pages/user/registerPage.dart';
import 'package:grad_qr_project/pages/user/resultPage.dart';
import 'package:grad_qr_project/pages/user/scanPage.dart';
import 'package:grad_qr_project/pages/user/searchPage.dart';

void main() async {
  // 3. Flutter motorunu hazırla
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 5. Konsola log bas
  if (kDebugMode) {
    print('-------------------------------------------');
  }
  if (kDebugMode) {
    print('Firebase başarıyla başlatıldı!');
  }
  if (kDebugMode) {
    print('-------------------------------------------');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Barcode Price Comparer',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF2E7D32),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF1B5E20),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            elevation: 2,
            // ignore: deprecated_member_use
            shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
          ),
          prefixIconColor: Colors.grey,
          labelStyle: const TextStyle(color: Colors.grey),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/scan': (context) => const ScanPage(),
        '/result': (context) => const ResultPage(),
        '/profile': (context) => const ProfilePage(),
        '/search': (context) => const SearchPage(),
        '/not-found': (context) => const NotFoundPage(),
        '/admin': (context) => const AdminDashboard(),
      },
    );
  }
}
