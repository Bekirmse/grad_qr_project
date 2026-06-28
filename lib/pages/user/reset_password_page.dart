
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isObscure = true;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _sendConfirmationEmail();
  }

  Future<void> _sendConfirmationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final email = user.email ?? '';
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() => _emailSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'A confirmation link has been sent to $email. Please check your inbox.',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send email: $e')),
        );
      }
    }
  }

  void _update() async {
    if (_passController.text.isEmpty || _confirmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (_passController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    if (_passController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final error = await _authService.updatePassword(_passController.text);
    setState(() => _isLoading = false);

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded, size: 50, color: Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'New Password',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 12),
              Text(
                'Your new password must be different\nfrom previously used passwords.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 24),

              if (_emailSent && email.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_read_outlined, color: Color(0xFF2E7D32), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'A confirmation email has been sent to $email',
                          style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              _buildPasswordInput(_passController, 'New Password'),
              const SizedBox(height: 16),
              _buildPasswordInput(_confirmController, 'Confirm Password'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _update,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Update Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : _sendConfirmationEmail,
                child: const Text(
                  'Resend confirmation email',
                  style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordInput(TextEditingController controller, String label) {
    return SizedBox(
      height: 55,
      child: TextField(
        controller: controller,
        obscureText: _isObscure,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 22),
          suffixIcon: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: () => setState(() => _isObscure = !_isObscure),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }
}
