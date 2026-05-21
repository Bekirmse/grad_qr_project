import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grad_qr_project/pages/user/reset_password_page.dart';
import 'firebase_options.dart';

import 'package:grad_qr_project/pages/admin/adminDashboard.dart';
import 'package:grad_qr_project/pages/user/homePage.dart' as home_page;
import 'package:grad_qr_project/pages/user/loginPage.dart';
import 'package:grad_qr_project/pages/user/notFoundPage.dart';
import 'package:grad_qr_project/pages/user/profilePage.dart';
import 'package:grad_qr_project/pages/user/registerPage.dart';
import 'package:grad_qr_project/pages/user/resultPage.dart';
import 'package:grad_qr_project/pages/user/scanPage.dart';
import 'package:grad_qr_project/pages/user/searchPage.dart';
import 'package:grad_qr_project/pages/user/editProfilePage.dart';
import 'package:grad_qr_project/pages/user/favoritesPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      // ignore: deprecated_member_use
      appleProvider: AppleProvider.deviceCheck,
      // ignore: deprecated_member_use
      androidProvider: AndroidProvider.debug,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ScanWiser',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: const Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F2F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
          ),
          prefixIconColor: const Color(0xFF9E9E9E),
          labelStyle: GoogleFonts.poppins(color: const Color(0xFF9E9E9E)),
          hintStyle: GoogleFonts.poppins(color: const Color(0xFFBDBDBD)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const home_page.HomePage(),
        '/scan': (context) => const ScanPage(),
        '/result': (context) => const ResultPage(barcode: ''),
        '/profile': (context) => const ProfilePage(),
        '/search': (context) => const SearchPage(),
        '/favorites': (context) => const FavoritesPage(),
        '/not-found': (context) => const NotFoundPage(),
        '/admin': (context) => const AdminDashboard(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/change-password': (context) => const ResetPasswordPage(),
      },
    );
  }
}
