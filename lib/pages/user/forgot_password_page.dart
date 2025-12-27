// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'verificationPage.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _sendCode() async {
    setState(() => _isLoading = true);
    String? phone = await _authService.getPhoneByEmail(
      _emailController.text.trim(),
    );

    if (phone == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not found')));
      }
      return;
    }

    await _authService.startPhoneAuth(
      phoneNumber: phone,
      onCodeSent: (verificationId, token) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => VerificationPage(
                  verificationId: verificationId,
                  isPasswordReset: true,
                ),
          ),
        );
      },
      onVerificationFailed: (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ekran yüksekliğini alıp simetrik yerleşim için kullanıyoruz
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 40, // AppBar'ı kompakt yaptık
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            // Ekran yüksekliği - AppBar - Paddingler = İçerik Alanı
            height:
                screenHeight -
                40 -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                // İçeriği dikey eksende eşit ve ortalı dağıt
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 1), // Üst boşluk
                  // --- İKON (Yuvarlak Arka Planlı) ---
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9), // Açık yeşil
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        size: 50,
                        color: Color(0xFF2E7D32), // Ana yeşil
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- BAŞLIK VE AÇIKLAMA ---
                  Column(
                    children: [
                      const Text(
                        'Forgot Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter your email to receive a code\non your registered phone number.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // --- INPUT ---
                  _buildCompactInput(
                    _emailController,
                    'Email Address',
                    Icons.email_outlined,
                  ),

                  const SizedBox(height: 24),

                  // --- BUTON ---
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Send Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),

                  const Spacer(flex: 2), // Alt boşluk (Klavye açılınca sıkışır)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Diğer sayfalardakiyle aynı kompakt input yapısı
  Widget _buildCompactInput(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return SizedBox(
      height: 55,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          prefixIcon: Icon(icon, color: Colors.grey, size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
        ),
      ),
    );
  }
}
