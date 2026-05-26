import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'astrologer_main_screen.dart';

const _specializations = ['Vedic Astrology', 'Tarot', 'Numerology', 'KP Astrology', 'Western Astrology', 'Face Reading', 'Vastu', 'Prashna'];
const _languages = ['Hindi', 'English', 'Tamil', 'Telugu', 'Kannada', 'Malayalam', 'Bengali', 'Marathi', 'Gujarati'];

class AstrologerSetupProfileScreen extends StatefulWidget {
  const AstrologerSetupProfileScreen({super.key});

  @override
  State<AstrologerSetupProfileScreen> createState() => _AstrologerSetupProfileScreenState();
}

class _AstrologerSetupProfileScreenState extends State<AstrologerSetupProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _expertiseCtrl = TextEditingController();

  List<String> _selectedSpecializations = [];
  List<String> _selectedLanguages = [];
  List<String> _expertiseAreas = [];
  double _chatRate = 10;
  double _callRate = 15;
  double _videoRate = 20;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _bioCtrl.dispose(); _expCtrl.dispose(); _expertiseCtrl.dispose();
    super.dispose();
  }

  void _toggleItem(List<String> list, String item, String key) {
    setState(() {
      if (list.contains(item)) list.remove(item); else list.add(item);
    });
  }

  void _addExpertise() {
    final text = _expertiseCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _expertiseAreas.add(text); _expertiseCtrl.clear(); });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one language')));
      return;
    }

    setState(() => _loading = true);
    try {
      final data = await ApiService.registerAsAstrologer({
        'display_name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'experience_years': int.tryParse(_expCtrl.text) ?? 0,
        'specializations': _selectedSpecializations,
        'languages': _selectedLanguages,
        'expertise_areas': _expertiseAreas,
        'per_minute_rate_chat': _chatRate,
        'per_minute_rate_call': _callRate,
        'per_minute_rate_video': _videoRate,
      });

      await context.read<AuthProvider>().refreshAstrologerProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Astrologer profile created! Awaiting approval.'), backgroundColor: AppColors.success),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AstrologerMainScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Setup Astrologer Profile', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('Basic Information', [
                _field(_nameCtrl, 'Display Name', 'Name shown to clients', required: true),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('Bio', 'Tell clients about yourself...'),
                  validator: (v) => v!.isEmpty ? 'Bio is required' : null,
                ),
                const SizedBox(height: 12),
                _field(_expCtrl, 'Years of Experience', 'e.g. 5', keyboardType: TextInputType.number, required: true),
              ]),
              const SizedBox(height: 16),
              _section('Specializations', [
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _specializations.map((s) => _chip(s, _selectedSpecializations, 'specializations')).toList(),
                ),
              ]),
              const SizedBox(height: 16),
              _section('Languages', [
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _languages.map((l) => _chip(l, _selectedLanguages, 'languages')).toList(),
                ),
              ]),
              const SizedBox(height: 16),
              _section('Expertise Areas', [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _expertiseCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration('Add area', 'e.g. Marriage, Career'),
                      onSubmitted: (_) => _addExpertise(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addExpertise,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ]),
                if (_expertiseAreas.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _expertiseAreas.map((a) => Chip(
                      label: Text(a, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: AppColors.orange.withOpacity(0.7),
                      deleteIconColor: Colors.white70,
                      onDeleted: () => setState(() => _expertiseAreas.remove(a)),
                    )).toList(),
                  ),
                ],
              ]),
              const SizedBox(height: 16),
              _section('Per Minute Rates (₹)', [
                _rateSlider('Chat Rate', _chatRate, (v) => setState(() => _chatRate = v)),
                _rateSlider('Call Rate', _callRate, (v) => setState(() => _callRate = v)),
                _rateSlider('Video Rate', _videoRate, (v) => setState(() => _videoRate = v)),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Complete Setup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, {TextInputType? keyboardType, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration(label, hint),
      validator: required ? (v) => v!.isEmpty ? '$label is required' : null : null,
    );
  }

  InputDecoration _inputDecoration(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textMuted),
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.orange)),
  );

  Widget _chip(String label, List<String> selected, String key) {
    final isSelected = selected.contains(label);
    return GestureDetector(
      onTap: () => _toggleItem(selected, label, key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orange : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.orange : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 13)),
      ),
    );
  }

  Widget _rateSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text('₹${value.toStringAsFixed(0)}/min', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
      ]),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: AppColors.orange,
          thumbColor: AppColors.orange,
          inactiveTrackColor: AppColors.border,
          overlayColor: AppColors.orange.withOpacity(0.2),
        ),
        child: Slider(value: value, min: 1, max: 100, divisions: 99, onChanged: onChanged),
      ),
    ]);
  }
}
