// ignore_for_file: file_names
import 'dart:async'; // Timer için gerekli
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import 'reset_password_page.dart';

class VerificationPage extends StatefulWidget {
  final String verificationId;
  final bool isPasswordReset;
  final String? phoneNumber; // Tekrar gönderim için gerekli

  const VerificationPage({
    super.key,
    required this.verificationId,
    this.isPasswordReset = false,
    this.phoneNumber,
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Geri sayım değişkenleri
  late String _currentVerificationId;
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _canResend = false;
      _start = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() => _start--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _resendCode() async {
    if (widget.phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number not found for resending.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    await _authService.startPhoneAuth(
      phoneNumber: widget.phoneNumber!,
      onCodeSent: (verificationId, forceResendingToken) {
        setState(() {
          _currentVerificationId = verificationId;
          _isLoading = false;
        });
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("A new code has been sent!"),
            backgroundColor: Colors.blue,
          ),
        );
      },
      onVerificationFailed: (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'SMS Error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _verify() async {
    setState(() => _isLoading = true);
    String smsCode = _controllers.map((e) => e.text).join();

    if (smsCode.length < 6) {
      setState(() => _isLoading = false);
      return;
    }

    String? error = await _authService.verifyOtpAndLogin(
      verificationId: _currentVerificationId,
      smsCode: smsCode,
    );

    if (error == null) {
      if (widget.isPasswordReset) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
        );
      } else {
        String role = await _authService.getUserRole();
        setState(() => _isLoading = false);
        if (role == 'admin') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin',
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  size: 50,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Verify It\'s You',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter the 6-digit code sent to\n${widget.phoneNumber ?? "your phone"}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildCodeBox(index)),
              ),
              const SizedBox(height: 30),

              // TEKRAR GONDER SİSTEMİ
              _canResend
                  ? TextButton(
                    onPressed: _isLoading ? null : _resendCode,
                    child: const Text(
                      "Resend SMS Code",
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  )
                  : Text(
                    "Resend code in $_start seconds",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Verify Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeBox(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _controllers[index],
        onChanged: (v) {
          if (v.length == 1 && index < 5) {
            FocusScope.of(context).nextFocus();
          } else if (v.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }
}
