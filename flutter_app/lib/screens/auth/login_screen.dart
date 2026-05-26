import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'register_screen.dart';
import '../home/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!success || !mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Color(0xFF2A1500), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                _buildHeader(s),
                const SizedBox(height: 40),
                _buildForm(s),
                const SizedBox(height: 24),
                _buildLoginButton(s),
                const SizedBox(height: 20),
                _buildRegisterLink(s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.orange.withOpacity(0.3)),
          ),
          child: const Icon(Icons.auto_awesome, color: AppColors.orange, size: 28),
        ),
        const SizedBox(height: 24),
        Text(
          s.welcomeBack,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          s.starsWaiting,
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildForm(AppStrings s) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => Form(
        key: _formKey,
        child: Column(
          children: [
            if (auth.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(auth.error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                ]),
              ),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: s.email, prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted)),
              validator: (v) => v!.contains('@') ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: s.password,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textMuted),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => v!.length >= 6 ? null : 'Password must be at least 6 characters',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(AppStrings s) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: auth.isLoading ? null : _login,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
          child: auth.isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(s.signIn),
        ),
      ),
    );
  }

  Widget _buildRegisterLink(AppStrings s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(s.dontHaveAccount, style: const TextStyle(color: AppColors.textSecondary)),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: Text(s.signUp, style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
