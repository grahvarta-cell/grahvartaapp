import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../astrologer/astrologer_main_screen.dart';
import '../astrologer/astrologer_setup_profile_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.changePassword(_currentCtrl.text, _newCtrl.text);
      if (!mounted) return;
      // Reload profile so mustChangePassword is now false
      final auth = context.read<AuthProvider>();
      await auth.refreshUser();
      if (!mounted) return;
      if (auth.isAstrologer) {
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const AstrologerMainScreen()), (_) => false);
      } else {
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const AstrologerSetupProfileScreen()), (_) => false);
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [const Color(0xFF0D1A3A), const Color(0xFF0D0D0D)]
                  : [const Color(0xFFE6F0FF), const Color(0xFFFFFFFF)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Header
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF027DFD).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF027DFD).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF027DFD), size: 28),
                  ),
                  const SizedBox(height: 24),
                  Text('Set New Password',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: context.clr.txtPrimary)),
                  const SizedBox(height: 8),
                  Text('For your security, please set a new password before continuing.',
                    style: TextStyle(fontSize: 14, color: context.clr.txtSecondary, height: 1.5)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF027DFD).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF027DFD).withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: Color(0xFF027DFD), size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'This step is mandatory. Use the temporary password sent to your email.',
                        style: TextStyle(color: context.clr.txtSecondary, fontSize: 12, height: 1.4),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 32),

                  // Error
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.clr.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.clr.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: context.clr.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: TextStyle(color: context.clr.error, fontSize: 13))),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(children: [
                      _PasswordField(
                        controller: _currentCtrl,
                        label: 'Temporary Password (from email)',
                        obscure: _obscureCurrent,
                        onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _PasswordField(
                        controller: _newCtrl,
                        label: 'New Password',
                        obscure: _obscureNew,
                        onToggle: () => setState(() => _obscureNew = !_obscureNew),
                        validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      _PasswordField(
                        controller: _confirmCtrl,
                        label: 'Confirm New Password',
                        obscure: _obscureConfirm,
                        onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (v) => v != _newCtrl.text ? 'Passwords do not match' : null,
                      ),
                    ]),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF027DFD),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Set Password & Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: context.clr.txtPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline, color: context.clr.txtMuted),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: context.clr.txtMuted),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
