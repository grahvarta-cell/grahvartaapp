import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _tobCtrl;
  late TextEditingController _placeCtrl;

  File? _pickedImage;
  bool _isSaving = false;
  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _dobCtrl = TextEditingController(text: user?.dateOfBirth ?? '');
    _tobCtrl = TextEditingController(text: user?.timeOfBirth ?? '');
    _placeCtrl = TextEditingController(text: user?.birthPlace ?? '');
    if (user?.dateOfBirth != null) {
      _selectedDob = DateTime.tryParse(user!.dateOfBirth!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _tobCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _pickDob() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (c, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: context.clr.accent)),
        child: child!,
      ),
    );
    if (d != null) {
      _selectedDob = d;
      _dobCtrl.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? avatarUrl;
      if (_pickedImage != null) {
        final result = await ApiService.uploadAvatar(_pickedImage!);
        avatarUrl = result['avatar_url'] as String?;
      }

      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'date_of_birth': _dobCtrl.text.isNotEmpty ? _dobCtrl.text : null,
        'time_of_birth': _tobCtrl.text.isNotEmpty ? _tobCtrl.text : null,
        'birth_place': _placeCtrl.text.isNotEmpty ? _placeCtrl.text : null,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

      await ApiService.updateProfile(payload);
      await context.read<AuthProvider>().refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully'), backgroundColor: context.clr.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: context.clr.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: context.clr.accent, strokeWidth: 2))
                : Text('Save', style: TextStyle(color: context.clr.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            // Avatar picker
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [context.clr.accent, context.clr.accentAlt]),
                      boxShadow: [BoxShadow(color: context.clr.accent.withValues(alpha: 0.3), blurRadius: 20)],
                    ),
                    child: _pickedImage != null
                        ? ClipOval(child: Image.file(_pickedImage!, fit: BoxFit.cover))
                        : (user?.avatarUrl != null
                            ? ClipOval(child: Image.network(user!.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials(user.name)))
                            : _initials(user?.name ?? 'U')),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: context.clr.accent, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Tap to change photo', style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
            const SizedBox(height: 28),

            _field('Full Name', _nameCtrl, Icons.person_outline, validator: (v) => v!.trim().isEmpty ? 'Name is required' : null),
            const SizedBox(height: 14),

            // Date of Birth
            GestureDetector(
              onTap: _pickDob,
              child: AbsorbPointer(
                child: _field('Date of Birth', _dobCtrl, Icons.cake_outlined),
              ),
            ),
            const SizedBox(height: 14),

            _field('Time of Birth', _tobCtrl, Icons.access_time_outlined, hint: 'e.g. 14:30'),
            const SizedBox(height: 14),

            _field('Birth Place', _placeCtrl, Icons.place_outlined, hint: 'City, Country'),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _initials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {String? hint, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      style: TextStyle(color: context.clr.txtPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: context.clr.txtMuted),
        labelStyle: TextStyle(color: context.clr.txtMuted),
        prefixIcon: Icon(icon, color: context.clr.txtMuted, size: 20),
        filled: true,
        fillColor: context.clr.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.clr.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.clr.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.clr.accent)),
      ),
    );
  }
}
