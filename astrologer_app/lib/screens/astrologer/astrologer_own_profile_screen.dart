import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'astrologer_earnings_screen.dart';

const _specializations = ['Vedic Astrology', 'Tarot', 'Numerology', 'KP Astrology', 'Western Astrology', 'Face Reading', 'Vastu', 'Prashna'];
const _languages = ['Hindi', 'English', 'Tamil', 'Telugu', 'Kannada', 'Malayalam', 'Bengali', 'Marathi', 'Gujarati'];

class AstrologerOwnProfileScreen extends StatefulWidget {
  const AstrologerOwnProfileScreen({super.key});

  @override
  State<AstrologerOwnProfileScreen> createState() => _AstrologerOwnProfileScreenState();
}

class _AstrologerOwnProfileScreenState extends State<AstrologerOwnProfileScreen> {
  bool _editing = false;
  bool _uploadingAvatar = false;

  // Edit form state
  late TextEditingController _bioCtrl;
  late TextEditingController _expCtrl;
  late List<String> _selectedSpecializations;
  late List<String> _selectedLanguages;
  double _chatRate = 10;
  double _callRate = 15;
  double _videoRate = 20;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initEditFields();
  }

  void _initEditFields() {
    final p = context.read<AuthProvider>().astrologerProfile;
    _bioCtrl = TextEditingController(text: p?.bio ?? '');
    _expCtrl = TextEditingController(text: p?.experienceYears.toString() ?? '');
    _selectedSpecializations = List.from(p?.specializations ?? []);
    _selectedLanguages = List.from(p?.languages ?? []);
    _chatRate = p?.perMinuteRateChat ?? 10;
    _callRate = p?.perMinuteRateCall ?? 15;
    _videoRate = p?.perMinuteRateVideo ?? 20;
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    try {
      // Note: update profile uses the astrologer update endpoint
      // For now we update user profile fields that are supported
      await ApiService.updateProfile({
        'bio': _bioCtrl.text.trim(),
      });
      await context.read<AuthProvider>().refreshAstrologerProfile();
      if (mounted) {
        setState(() { _editing = false; _saving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated!'), backgroundColor: context.clr.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: context.clr.error));
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.clr.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: context.clr.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.camera_alt_rounded, color: context.clr.accent),
            title: Text('Take a photo', style: TextStyle(color: context.clr.txtPrimary)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library_rounded, color: context.clr.accent),
            title: Text('Choose from gallery', style: TextStyle(color: context.clr.txtPrimary)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 512);
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      await ApiService.uploadAvatar(File(picked.path));
      await context.read<AuthProvider>().refreshAstrologerProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile photo updated!'), backgroundColor: context.clr.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: context.clr.error),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final profile = auth.astrologerProfile;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.clr.surface,
        title: Text('My Profile', style: TextStyle(color: context.clr.txtPrimary)),
        actions: [
          if (!_editing)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: context.clr.txtPrimary),
              onPressed: () => setState(() => _editing = true),
            )
          else ...[
            TextButton(
              onPressed: () { setState(() { _editing = false; _initEditFields(); }); },
              child: Text('Cancel', style: TextStyle(color: context.clr.txtSecondary)),
            ),
            TextButton(
              onPressed: _saving ? null : _saveChanges,
              child: _saving
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: context.clr.accent))
                  : Text('Save', style: TextStyle(color: context.clr.accent, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(user, profile),
            const SizedBox(height: 16),
            if (_editing) _buildEditForm() else _buildViewMode(profile),
            const SizedBox(height: 24),
            _buildEarningsCard(),
            const SizedBox(height: 24),
            _buildLogoutButton(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(user, profile) {
    final name = profile?.displayName ?? user?.name ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    final avatarUrl = profile?.avatarUrl ?? user?.avatarUrl;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.clr.border)),
      child: Column(children: [
        GestureDetector(
          onTap: _editing ? _pickAndUploadAvatar : null,
          child: Stack(alignment: Alignment.bottomRight, children: [
            _uploadingAvatar
                ? Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: context.clr.accent.withValues(alpha: 0.2)),
                    child: Center(child: CircularProgressIndicator(color: context.clr.accent, strokeWidth: 2)),
                  )
                : CircleAvatar(
                    radius: 40,
                    backgroundColor: context.clr.accent.withValues(alpha: 0.2),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null ? Text(initials, style: TextStyle(color: context.clr.accent, fontSize: 28, fontWeight: FontWeight.bold)) : null,
                  ),
            if (_editing)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: context.clr.accent, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Text(name, style: TextStyle(color: context.clr.txtPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        if (profile != null) ...[
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: profile.isApproved ? context.clr.success.withValues(alpha: 0.15) : const Color(0xFFFFD700).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                profile.isApproved ? 'Approved Astrologer' : profile.approvalStatus.toUpperCase(),
                style: TextStyle(color: profile.isApproved ? context.clr.success : const Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _headerStat('${profile.rating.toStringAsFixed(1)}', 'Rating', Icons.star, const Color(0xFFFFD700)),
            _vDivider(),
            _headerStat('${profile.totalConsultations}', 'Consults', Icons.people_rounded, context.clr.accent),
            _vDivider(),
            _headerStat('${profile.reviewCount}', 'Reviews', Icons.comment_outlined, Colors.blue),
          ]),
        ],
      ]),
    );
  }

  Widget _headerStat(String value, String label, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
    ]);
  }

  Widget _vDivider() => Container(height: 40, width: 1, color: context.clr.border);

  Widget _buildViewMode(AstrologerProfile? profile) {
    if (profile == null) return const SizedBox();
    return Column(children: [
      if (profile.bio != null && profile.bio!.isNotEmpty)
        _infoCard('Bio', profile.bio!),
      if (profile.specializations.isNotEmpty)
        _chipCard('Specializations', profile.specializations),
      if (profile.languages.isNotEmpty)
        _chipCard('Languages', profile.languages),
      if (profile.expertiseAreas.isNotEmpty)
        _chipCard('Expertise Areas', profile.expertiseAreas),
      _ratesCard(profile),
    ]);
  }

  Widget _infoCard(String title, String content, {int? scrollableLines}) {
    final textStyle = TextStyle(color: context.clr.txtPrimary, fontSize: 14, height: 1.5);
    final contentWidget = scrollableLines != null
        ? ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 14 * 1.5 * scrollableLines),
            child: SingleChildScrollView(
              child: Text(content, style: textStyle),
            ),
          )
        : Text(content, style: textStyle);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.clr.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: context.clr.txtSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        contentWidget,
      ]),
    );
  }

  Widget _chipCard(String title, List<String> items) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.clr.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: context.clr.txtSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: items.map((i) =>
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: context.clr.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: context.clr.accent.withValues(alpha: 0.3))),
            child: Text(i, style: TextStyle(color: context.clr.accent, fontSize: 12)),
          )
        ).toList()),
      ]),
    );
  }

  Widget _ratesCard(AstrologerProfile profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.clr.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Per Minute Rates', style: TextStyle(color: context.clr.txtSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(children: [
          _rateItem('Chat', profile.perMinuteRateChat),
          _rateItem('Call', profile.perMinuteRateCall),
          _rateItem('Video', profile.perMinuteRateVideo),
        ]),
      ]),
    );
  }

  Widget _rateItem(String label, double rate) {
    return Expanded(child: Column(children: [
      Text('₹${rate.toStringAsFixed(0)}/min', style: TextStyle(color: context.clr.accent, fontSize: 15, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
    ]));
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.clr.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Edit Profile', style: TextStyle(color: context.clr.txtPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _bioCtrl,
          maxLines: 4,
          style: TextStyle(color: context.clr.txtPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Bio',
            labelStyle: TextStyle(color: context.clr.txtSecondary),
            filled: true, fillColor: context.clr.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.clr.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.clr.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.clr.accent)),
          ),
        ),
      ]),
    );
  }

  Widget _buildEarningsCard() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AstrologerEarningsScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.clr.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.clr.border),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: context.clr.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.account_balance_wallet_rounded, color: context.clr.accent, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Earnings & Wallet', style: TextStyle(color: context.clr.txtPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              Text('View transactions & request withdrawal', style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: context.clr.txtMuted),
        ]),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: Icon(Icons.logout, color: context.clr.error),
        label: Text('Logout', style: TextStyle(color: context.clr.error)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.clr.error.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
