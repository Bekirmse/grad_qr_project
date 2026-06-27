
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isObscure = true;
  bool _isLoading = false;

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final adminSnapshot =
          await FirebaseFirestore.instance
              .collection('admins')
              .where('email', isEqualTo: email)
              .where('password', isEqualTo: password)
              .get();

      if (adminSnapshot.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome Admin! Redirecting...'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() => _isLoading = false);
          Navigator.pushReplacementNamed(context, '/admin');
        }
        return;
      }
    } catch (e) {
      debugPrint("Admin kontrol hatası: $e");
    }


    String? error = await _authService.checkCredentials(email, password);

    if (error != null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    try {
      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;

        if (_authService.isEmailVerified()) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'isVerified': true});
          setState(() => _isLoading = false);
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          }
          return;
        }

        try {
          await _authService.sendEmailVerification();
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification email sent. Please verify and login again.'),
                backgroundColor: Color(0xFF2E7D32),
              ),
            );
            await Future.delayed(const Duration(seconds: 2));
            Navigator.pushReplacementNamed(context, '/login');
          }
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.toString()}')),
            );
          }
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User record not found in database.')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("System Error: $e")));
      }
    }
  }

  Future<void> _socialLogin(String provider) async {
    setState(() => _isLoading = true);

    String? error;

    try {
      if (provider == 'Google') {
        error = await _authService.signInWithGoogle();
      } else if (provider == 'Apple') {
        error = await _authService.signInWithApple();
      }

      if (error == null && mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Login failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$provider login error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight + 20),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 50,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Welcome to ScanWiser!',
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
                        'Sign in to compare prices & save money',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 40),

                      _buildInput(
                        _emailController,
                        'Email Address',
                        Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordInput(),

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ForgotPasswordPage(),
                                ),
                              ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
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
                                ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),

                      const SizedBox(height: 30),

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Or continue with",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            'assets/google.png',
                            "Google",
                            () => _socialLogin('Google'),
                          ),
                          const SizedBox(width: 20),
                          _buildSocialButton(
                            'assets/apple.png',
                            "Apple",
                            () => _socialLogin('Apple'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                () => Navigator.pushNamed(context, '/register'),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
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
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
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

  Widget _buildPasswordInput() {
    return TextField(
      controller: _passwordController,
      obscureText: _isObscure,
      decoration: InputDecoration(
        labelText: 'Password',
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

  Widget _buildSocialButton(
    String assetPath,
    String label,
    VoidCallback onTap,
  ) {
    IconData icon = label == "Google" ? Icons.g_mobiledata : Icons.apple;
    Color color = label == "Google" ? Colors.red : Colors.black;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
