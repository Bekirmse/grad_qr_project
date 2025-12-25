// ignore_for_file: file_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'verificationPage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isObscure = true;
  bool _isLoading = false;

  void _register() async {
    debugPrint("🔴 LOG: Kayıt işlemi tetiklendi.");

    // 1. Şifre Eşleşme Kontrolü
    if (_passwordController.text != _confirmPasswordController.text) {
      debugPrint("🔴 LOG: Hata - Şifreler uyuşmuyor.");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    // 2. Alanların Doluluk Kontrolü
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      debugPrint("🔴 LOG: Hata - Boş alanlar var.");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    debugPrint("🔴 LOG: Loading açıldı, işlemler başlıyor...");

    // 3. Telefon Numarası Formatlama
    String phone = _phoneController.text.trim();
    if (phone.isNotEmpty && !phone.startsWith('+')) {
      phone = '+90$phone';
    }
    debugPrint("🔴 LOG: Telefon numarası formatlandı: $phone");

    try {
      // 4. KAYIT İŞLEMİ
      debugPrint("🔴 LOG: AuthService.registerUser çağrılıyor...");

      String? error = await _authService.registerUser(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: phone,
      );

      debugPrint(
        "🔴 LOG: registerUser tamamlandı. Sonuç (Hata varsa yazar): $error",
      );

      if (error == null) {
        debugPrint("🔴 LOG: Kayıt başarılı (Firestore'a yazıldı).");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Sending verification code...'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }

        // 5. SMS Gönderimi
        debugPrint("🔴 LOG: startPhoneAuth (SMS Gönderimi) başlatılıyor...");

        await _authService.startPhoneAuth(
          phoneNumber: phone,
          onCodeSent: (verificationId, forceResendingToken) {
            debugPrint(
              "🟢 LOG: SMS Kodu başarıyla gönderildi! VerificationID: $verificationId",
            );

            setState(() => _isLoading = false);
            debugPrint(
              "🟢 LOG: Loading kapatıldı, VerificationPage'e gidiliyor.",
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => VerificationPage(
                      verificationId: verificationId,
                      isPasswordReset: false,
                    ),
              ),
            );
          },
          onVerificationFailed: (e) {
            debugPrint("🔴 LOG: SMS Gönderme HATASI: ${e.code} - ${e.message}");

            setState(() => _isLoading = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('SMS Error: ${e.message}')));
          },
        );

        debugPrint(
          "🔴 LOG: startPhoneAuth fonksiyonu tetiklendi (Sonuç bekleniyor).",
        );
      } else {
        debugPrint("🔴 LOG: Kayıt sırasında hata oluştu: $error");
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint("🔴 LOG: KRİTİK HATA (Try-Catch): $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('System Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI kısmını değiştirmedim, aynı şekilde bıraktım.
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 60,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 40,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join us to find the best prices',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 40),

                      _buildInput(
                        _nameController,
                        'Full Name',
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildInput(
                        _emailController,
                        'Email Address',
                        Icons.email_outlined,
                        type: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildInput(
                        _phoneController,
                        'Phone Number',
                        Icons.phone,
                        hint: '533 123 45 67',
                        prefixText: '+90 ',
                        type: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordInput(_passwordController, 'Password'),
                      const SizedBox(height: 16),
                      _buildPasswordInput(
                        _confirmPasswordController,
                        'Confirm Password',
                      ),

                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    String? prefixText,
    TextInputType? type,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }

  Widget _buildPasswordInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: _isObscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => _isObscure = !_isObscure),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }
}
