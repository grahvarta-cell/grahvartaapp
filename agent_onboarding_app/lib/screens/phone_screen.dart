import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import 'registration_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});
  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _verificationId;
  String? _error;

  Future<void> _sendOtp() async {
    final phone = '+91${_phoneCtrl.text.trim()}';
    if (_phoneCtrl.text.trim().length != 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) _goToRegistration(phone);
      },
      verificationFailed: (e) {
        setState(() { _loading = false; _error = e.message ?? 'Verification failed'; });
      },
      codeSent: (id, _) {
        setState(() { _verificationId = id; _otpSent = true; _loading = false; });
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) _goToRegistration('+91${_phoneCtrl.text.trim()}');
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message ?? 'Invalid OTP'; _loading = false; });
    }
  }

  void _goToRegistration(String phone) {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => RegistrationScreen(phone: phone),
    ));
  }

  @override
  void dispose() { _phoneCtrl.dispose(); _otpCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('Grahvarta', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 6),
              const Text('Agent Onboarding', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 48),
              if (!_otpSent) ...[
                const Align(alignment: Alignment.centerLeft, child: Text('Enter your mobile number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(prefixText: '+91  ', labelText: 'Mobile Number', counterText: ''),
                ),
                const SizedBox(height: 8),
                const Text('We will send an OTP to verify your number', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ] else ...[
                const Align(alignment: Alignment.centerLeft, child: Text('Enter OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Sent to +91 ${_phoneCtrl.text}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 12),
                  decoration: const InputDecoration(labelText: 'OTP', counterText: ''),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() { _otpSent = false; _otpCtrl.clear(); }),
                  child: const Text('Change number?', style: TextStyle(color: AppColors.primary)),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : ElevatedButton(
                      onPressed: _otpSent ? _verifyOtp : _sendOtp,
                      child: Text(_otpSent ? 'Verify & Continue' : 'Send OTP'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
