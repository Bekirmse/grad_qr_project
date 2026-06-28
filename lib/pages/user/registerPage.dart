// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isObscure = true;
  bool _isConfirmObscure = true;
  bool _isLoading = false;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _generalError;

  bool _validate() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    bool valid = true;

    _nameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmError = null;
    _generalError = null;

    if (name.isEmpty) {
      _nameError = 'Please enter your full name.';
      valid = false;
    }

    if (email.isEmpty) {
      _emailError = 'Please enter your email address.';
      valid = false;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _emailError = 'Please enter a valid email address.';
      valid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'Please enter a password.';
      valid = false;
    } else if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters.';
      valid = false;
    }

    if (confirm.isEmpty) {
      _confirmError = 'Please confirm your password.';
      valid = false;
    } else if (password != confirm) {
      _confirmError = 'Passwords do not match.';
      valid = false;
    }

    return valid;
  }

  void _register() async {
    if (!_validate()) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      final error = await _authService.registerUser(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (error == null) {
        await _authService.sendEmailVerification();

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Verification email sent. Please verify your email before logging in.'),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        }
      } else {
        setState(() {
          _isLoading = false;
          if (error.toLowerCase().contains('email') || error.toLowerCase().contains('use')) {
            _emailError = error;
          } else if (error.toLowerCase().contains('password') || error.toLowerCase().contains('weak')) {
            _passwordError = error;
          } else {
            _generalError = error;
          }
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
        _generalError = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 60),
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
                          decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                          child: const Icon(Icons.person_add_alt_1_rounded, size: 40, color: Color(0xFF2E7D32)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), letterSpacing: -0.5),
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
                        error: _nameError,
                        onChanged: (_) { if (_nameError != null) setState(() => _nameError = null); },
                      ),
                      const SizedBox(height: 16),
                      _buildInput(
                        _emailController,
                        'Email Address',
                        Icons.email_outlined,
                        error: _emailError,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) { if (_emailError != null) setState(() => _emailError = null); },
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordInput(
                        _passwordController,
                        'Password',
                        obscure: _isObscure,
                        onToggle: () => setState(() => _isObscure = !_isObscure),
                        error: _passwordError,
                        onChanged: (_) { if (_passwordError != null) setState(() => _passwordError = null); },
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordInput(
                        _confirmPasswordController,
                        'Confirm Password',
                        obscure: _isConfirmObscure,
                        onToggle: () => setState(() => _isConfirmObscure = !_isConfirmObscure),
                        error: _confirmError,
                        onChanged: (_) { if (_confirmError != null) setState(() => _confirmError = null); },
                      ),

                      if (_generalError != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorBox(_generalError!),
                      ],

                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text('Login', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13)),
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

  Widget _buildPasswordInput(
    TextEditingController controller,
    String label, {
    required bool obscure,
    required VoidCallback onToggle,
    String? error,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: error != null ? const Color(0xFFFFF3F3) : const Color(0xFFF5F5F5),
            prefixIcon: Icon(Icons.lock_outline, color: error != null ? const Color(0xFFC62828) : Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
              onPressed: onToggle,
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
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFC62828), fontSize: 12))),
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
}
