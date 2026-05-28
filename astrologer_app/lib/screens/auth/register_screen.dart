import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../home/main_screen.dart';
import '../astrologer/astrologer_setup_profile_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool isAstrologerMode;
  const RegisterScreen({super.key, this.isAstrologerMode = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _birthPlaceCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _currentStep = 0;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _birthPlaceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(primary: context.clr.accent, surface: context.clr.card),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(primary: context.clr.accent, surface: context.clr.card),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<AuthProvider>().register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      dateOfBirth: _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null,
      timeOfBirth: _selectedTime != null ? '${_selectedTime!.hour}:${_selectedTime!.minute}:00' : null,
      birthPlace: _birthPlaceCtrl.text.isEmpty ? null : _birthPlaceCtrl.text.trim(),
    );
    if (!success || !mounted) return;
    if (widget.isAstrologerMode) {
      // After account creation, go straight to astrologer profile setup
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AstrologerSetupProfileScreen()),
        (_) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    }
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
            colors: [context.clr.surface, context.clr.bg],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(s),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: _currentStep == 0 ? _buildStep1(s) : _buildStep2(s),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AppStrings s) {
    final isAstro = widget.isAstrologerMode;
    final accentColor = isAstro ? const Color(0xFFFFD700) : context.clr.accent;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: context.clr.txtPrimary),
            onPressed: _currentStep == 0 ? () => Navigator.pop(context) : () => setState(() => _currentStep = 0),
          ),
          Expanded(
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (isAstro) ...[
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 14),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    _currentStep == 0
                        ? (isAstro ? 'Astrologer Account' : s.createAccount)
                        : s.birthDetails,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.clr.txtPrimary),
                  ),
                ]),
                const SizedBox(height: 6),
                if (!widget.isAstrologerMode)
                  LinearProgressIndicator(
                    value: _currentStep == 0 ? 0.5 : 1.0,
                    backgroundColor: context.clr.border,
                    color: accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStep1(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.joinCosmos, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: context.clr.txtPrimary)),
        const SizedBox(height: 8),
        Text(s.createCosmicProfile, style: TextStyle(color: context.clr.txtSecondary)),
        const SizedBox(height: 32),
        TextFormField(
          controller: _nameCtrl,
          style: TextStyle(color: context.clr.txtPrimary),
          decoration: InputDecoration(labelText: s.fullName, prefixIcon: Icon(Icons.person_outline, color: context.clr.txtMuted)),
          validator: (v) => v!.length >= 2 ? null : s.name,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: context.clr.txtPrimary),
          decoration: InputDecoration(labelText: s.emailAddress, prefixIcon: Icon(Icons.email_outlined, color: context.clr.txtMuted)),
          validator: (v) => v!.contains('@') ? null : s.email,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePassword,
          style: TextStyle(color: context.clr.txtPrimary),
          decoration: InputDecoration(
            labelText: s.password,
            prefixIcon: Icon(Icons.lock_outline, color: context.clr.txtMuted),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: context.clr.txtMuted),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) => v!.length >= 6 ? null : s.password,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (widget.isAstrologerMode) {
              _register(); // skip birth details for astrologers
            } else {
              setState(() => _currentStep = 1);
            }
          },
          child: Text(widget.isAstrologerMode ? 'Create Account' : s.continueText),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(s.alreadyHaveAccount, style: TextStyle(color: context.clr.txtSecondary)),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(s.signIn, style: TextStyle(color: context.clr.accent, fontWeight: FontWeight.w600)),
          ),
        ]),
      ],
    );
  }

  Widget _buildStep2(AppStrings s) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.cosmicBlueprint, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: context.clr.txtPrimary)),
          const SizedBox(height: 8),
          Text(s.birthHelpChart, style: TextStyle(color: context.clr.txtSecondary)),
          const SizedBox(height: 32),
          _buildDatePicker(s),
          const SizedBox(height: 16),
          _buildTimePicker(s),
          const SizedBox(height: 16),
          TextFormField(
            controller: _birthPlaceCtrl,
            style: TextStyle(color: context.clr.txtPrimary),
            decoration: InputDecoration(labelText: s.birthPlace, prefixIcon: Icon(Icons.location_on_outlined, color: context.clr.txtMuted)),
          ),
          if (auth.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.clr.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(auth.error!, style: TextStyle(color: context.clr.error)),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: auth.isLoading ? null : _register,
            child: auth.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(s.beginJourney),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: auth.isLoading ? null : _register,
            child: Text(s.skipForNow, style: TextStyle(color: context.clr.txtSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(AppStrings s) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.clr.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.clr.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: context.clr.txtMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate != null ? DateFormat('MMMM d, yyyy').format(_selectedDate!) : s.dateOfBirth,
                style: TextStyle(color: _selectedDate != null ? context.clr.txtPrimary : context.clr.txtMuted, fontSize: 14),
              ),
            ),
            Icon(Icons.chevron_right, color: context.clr.txtMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(AppStrings s) {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.clr.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.clr.border),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_outlined, color: context.clr.txtMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedTime != null ? _selectedTime!.format(context) : s.timeOfBirth,
                style: TextStyle(color: _selectedTime != null ? context.clr.txtPrimary : context.clr.txtMuted, fontSize: 14),
              ),
            ),
            Icon(Icons.chevron_right, color: context.clr.txtMuted),
          ],
        ),
      ),
    );
  }
}
