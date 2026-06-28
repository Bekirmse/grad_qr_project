// ignore_for_file: file_names

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
  bool _showVerificationBanner = false;
  bool _resendLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  void _clearErrors() {
    _emailError = null;
    _passwordError = null;
    _generalError = null;
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    bool valid = true;

    if (email.isEmpty) {
      _emailError = 'Please enter your email address.';
      valid = false;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _emailError = 'Please enter a valid email address.';
      valid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'Please enter your password.';
      valid = false;
    }

    return valid;
  }

  Future<void> _resendVerification() async {
    setState(() => _resendLoading = true);
    try {
      await _authService.sendEmailVerification();
      if (mounted) _showSnackBar('Verification email resent. Please check your inbox.', success: true);
    } catch (_) {
      if (mounted) _showSnackBar('Could not resend verification email. Please try again.');
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _login() async {
    setState(_clearErrors);

    if (!_validate()) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final error = await _authService.checkCredentials(email, password);

    if (error != null) {
      setState(() {
        _isLoading = false;
        if (error.toLowerCase().contains('password') || error.toLowerCase().contains('incorrect')) {
          _passwordError = error;
        } else {
          _generalError = error;
        }
      });
      return;
    }

    try {
      final uid = _authService.currentUserId();
      if (uid == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await _authService.signOut();
        setState(() {
          _isLoading = false;
          _generalError = 'Your account was not found. Please contact support.';
        });
        return;
      }

      final role = userDoc.data()?['role'] ?? 'user';

      if (role == 'admin') {
        setState(() => _isLoading = false);
        if (mounted) {
          _showSnackBar('Welcome Admin! Redirecting...', success: true);
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pushReplacementNamed(context, '/admin');
        }
        return;
      }

      if (_authService.isEmailVerified()) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'isVerified': true});
        setState(() => _isLoading = false);
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        return;
      }

      try {
        await _authService.sendEmailVerification();
      } catch (_) {}

      setState(() {
        _isLoading = false;
        _showVerificationBanner = true;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _generalError = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _socialLogin(String provider) async {
    setState(() => _isLoading = true);

    try {
      String? error;
      if (provider == 'Google') {
        error = await _authService.signInWithGoogle();
      } else if (provider == 'Apple') {
        error = await _authService.signInWithApple();
      }

      if (error == null && mounted) {
        final uid = _authService.currentUserId();
        if (uid != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (!doc.exists) {
            await _authService.signOut();
            setState(() {
              _isLoading = false;
              _generalError = 'Your account was not found. Please contact support.';
            });
            return;
          }
        }
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else if (mounted && error != null) {
        _showSnackBar(error);
      }
    } catch (_) {
      if (mounted) _showSnackBar('Could not sign in with $provider. Please try again.');
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
                          decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                          child: const Icon(Icons.qr_code_scanner_rounded, size: 50, color: Color(0xFF2E7D32)),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Welcome to ScanWiser!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), letterSpacing: -0.5),
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
                        error: _emailError,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) {
                          if (_emailError != null || _generalError != null) {
                            setState(() { _emailError = null; _generalError = null; });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordInput(error: _passwordError),

                      if (_generalError != null) ...[
                        const SizedBox(height: 12),
                        _buildErrorBox(_generalError!),
                      ],

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                          ),
                          child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (_showVerificationBanner)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFFB300)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.mark_email_unread_outlined, color: Color(0xFFE65100), size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Email address not verified',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100), fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'A verification link has been sent to your email. Please click the link to verify your account, then try logging in again.',
                                style: TextStyle(color: Color(0xFF5D4037), fontSize: 13),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: _resendLoading ? null : _resendVerification,
                                child: Row(
                                  children: [
                                    _resendLoading
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)))
                                        : const Icon(Icons.refresh, size: 16, color: Color(0xFF2E7D32)),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Resend verification email',
                                      style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),

                      const SizedBox(height: 30),

                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("Or continue with", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton('Google', Icons.g_mobiledata, Colors.red, () => _socialLogin('Google')),
                          const SizedBox(width: 20),
                          _buildSocialButton('Apple', Icons.apple, Colors.black, () => _socialLogin('Apple')),
                        ],
                      ),

                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ", style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/register'),
                            child: const Text('Sign Up', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 15)),
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
    IconData icon, {
    String? error,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: error != null ? const Color(0xFFFFF3F3) : const Color(0xFFF5F5F5),
            prefixIcon: Icon(icon, color: error != null ? const Color(0xFFC62828) : Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: error != null ? const Color(0xFFC62828) : const Color(0xFF2E7D32), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: error != null ? const BorderSide(color: Color(0xFFEF9A9A), width: 1) : BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
        ),
        if (error != null) _buildFieldError(error),
      ],
    );
  }

  Widget _buildPasswordInput({String? error}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _passwordController,
          obscureText: _isObscure,
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
          decoration: InputDecoration(
            labelText: 'Password',
            filled: true,
            fillColor: error != null ? const Color(0xFFFFF3F3) : const Color(0xFFF5F5F5),
            prefixIcon: Icon(Icons.lock_outline, color: error != null ? const Color(0xFFC62828) : Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
              onPressed: () => setState(() => _isObscure = !_isObscure),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: error != null ? const Color(0xFFC62828) : const Color(0xFF2E7D32), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: error != null ? const BorderSide(color: Color(0xFFEF9A9A), width: 1) : BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
        ),
        if (error != null) _buildFieldError(error),
      ],
    );
  }

  Widget _buildFieldError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: Color(0xFFC62828)),
          const SizedBox(width: 4),
          Text(message, style: const TextStyle(color: Color(0xFFC62828), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFC62828)),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFC62828), fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon, Color color, VoidCallback onTap) {
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
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
