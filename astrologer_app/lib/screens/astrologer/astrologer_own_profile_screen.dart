import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../cubits/own_profile_cubit.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/change_password_screen.dart';
import 'astrologer_earnings_screen.dart';


class AstrologerOwnProfileScreen extends StatelessWidget {
  const AstrologerOwnProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OwnProfileCubit(),
      child: const _AstrologerOwnProfileView(),
    );
  }
}

class _AstrologerOwnProfileView extends StatefulWidget {
  const _AstrologerOwnProfileView();

  @override
  State<_AstrologerOwnProfileView> createState() => _AstrologerOwnProfileViewState();
}

class _AstrologerOwnProfileViewState extends State<_AstrologerOwnProfileView> {
  late TextEditingController _bioCtrl;
  late TextEditingController _expCtrl;

  @override
  void initState() {
    super.initState();
    _initEditFields();
  }

  void _initEditFields() {
    final p = context.read<AuthProvider>().astrologerProfile;
    _bioCtrl = TextEditingController(text: p?.bio ?? '');
    _expCtrl = TextEditingController(text: p?.experienceYears.toString() ?? '');
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(OwnProfileCubit cubit) async {
    cubit.setSaving(true);
    final auth = context.read<AuthProvider>();
    try {
      await ApiService.updateProfile({'bio': _bioCtrl.text.trim()});
      await auth.refreshAstrologerProfile();
      if (mounted) {
        cubit.doneEditing();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Profile updated!'), backgroundColor: context.clr.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: context.clr.error),
        );
        cubit.setSaving(false);
      }
    }
  }

  Future<void> _pickAndUploadAvatar(OwnProfileCubit cubit) async {
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

    final auth = context.read<AuthProvider>();
    cubit.setUploadingAvatar(true);
    try {
      await ApiService.uploadAvatar(File(picked.path));
      await auth.refreshAstrologerProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Profile photo updated!'), backgroundColor: context.clr.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: context.clr.error),
        );
      }
    } finally {
      if (mounted) cubit.setUploadingAvatar(false);
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

    return BlocBuilder<OwnProfileCubit, OwnProfileState>(
      builder: (context, state) {
        final cubit = context.read<OwnProfileCubit>();
        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.clr.surface,
            title: const Text('My Profile', style: TextStyle(color: Colors.white)),
            actions: [
              if (!state.editing)
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: context.clr.txtPrimary),
                  onPressed: cubit.startEditing,
                )
              else ...[
                TextButton(
                  onPressed: () {
                    cubit.cancelEditing();
                    _initEditFields();
                  },
                  child: Text('Cancel', style: TextStyle(color: context.clr.txtSecondary)),
                ),
                TextButton(
                  onPressed: state.saving ? null : () => _saveChanges(cubit),
                  child: state.saving
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
                  _buildHeader(context, state, cubit, user, profile),
                  const SizedBox(height: 16),
                  if (state.editing) _buildEditForm(context) else _buildViewMode(context, profile),
                  const SizedBox(height: 24),
                  _buildEarningsCard(context),
                  const SizedBox(height: 24),
                  _buildSettingsCard(context),
                  const SizedBox(height: 24),
                  _buildLogoutButton(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, OwnProfileState state, OwnProfileCubit cubit, user, profile) {
    final name = profile?.displayName ?? user?.name ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    final avatarUrl = profile?.avatarUrl ?? user?.avatarUrl;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.clr.border)),
      child: Column(children: [
        GestureDetector(
          onTap: state.editing ? () => _pickAndUploadAvatar(cubit) : null,
          child: Stack(alignment: Alignment.bottomRight, children: [
            state.uploadingAvatar
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
            if (state.editing)
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
                color: profile.isApproved ? context.clr.success.withValues(alpha: 0.15) : const Color(0xFFFFD700).withValues(alpha: 0.15),
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
            _headerStat(context, '${profile.rating.toStringAsFixed(1)}', 'Rating', Icons.star, const Color(0xFFFFD700)),
            _vDivider(context),
            _headerStat(context, '${profile.totalConsultations}', 'Consults', Icons.people_rounded, context.clr.accent),
            _vDivider(context),
            _headerStat(context, '${profile.reviewCount}', 'Reviews', Icons.comment_outlined, Colors.blue),
          ]),
        ],
      ]),
    );
  }

  Widget _headerStat(BuildContext context, String value, String label, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
    ]);
  }

  Widget _vDivider(BuildContext context) => Container(height: 40, width: 1, color: context.clr.border);

  Widget _buildViewMode(BuildContext context, AstrologerProfile? profile) {
    if (profile == null) return const SizedBox();
    return Column(children: [
      if (profile.bio != null && profile.bio!.isNotEmpty) _infoCard(context, 'Bio', profile.bio!),
      if (profile.specializations.isNotEmpty) _chipCard(context, 'Specializations', profile.specializations),
      if (profile.languages.isNotEmpty) _chipCard(context, 'Languages', profile.languages),
      if (profile.expertiseAreas.isNotEmpty) _chipCard(context, 'Expertise Areas', profile.expertiseAreas),
      _ratesCard(context, profile),
    ]);
  }

  Widget _infoCard(BuildContext context, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.clr.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: context.clr.txtSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(content, style: TextStyle(color: context.clr.txtPrimary, fontSize: 14, height: 1.5)),
      ]),
    );
  }

  Widget _chipCard(BuildContext context, String title, List<String> items) {
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
            decoration: BoxDecoration(
              color: context.clr.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.clr.accent.withValues(alpha: 0.3)),
            ),
            child: Text(i, style: TextStyle(color: context.clr.accent, fontSize: 12)),
          )
        ).toList()),
      ]),
    );
  }

  Widget _ratesCard(BuildContext context, AstrologerProfile profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.clr.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Per Minute Rates', style: TextStyle(color: context.clr.txtSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(children: [
          _rateItem(context, 'Chat', profile.perMinuteRateChat),
          _rateItem(context, 'Call', profile.perMinuteRateCall),
          _rateItem(context, 'Video', profile.perMinuteRateVideo),
        ]),
      ]),
    );
  }

  Widget _rateItem(BuildContext context, String label, double rate) {
    return Expanded(child: Column(children: [
      Text('₹${rate.toStringAsFixed(0)}/min', style: TextStyle(color: context.clr.accent, fontSize: 15, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
    ]));
  }

  Widget _buildEditForm(BuildContext context) {
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

  Widget _buildEarningsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AstrologerEarningsScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.clr.border)),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: context.clr.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.account_balance_wallet_rounded, color: context.clr.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Earnings & Wallet', style: TextStyle(color: context.clr.txtPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            Text('View transactions & request withdrawal', style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
          ])),
          Icon(Icons.chevron_right_rounded, color: context.clr.txtMuted),
        ]),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.clr.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Settings', style: TextStyle(color: context.clr.txtSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildSettingsTile(
          context,
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          subtitle: 'Update your account password',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen(isSettings: true))),
        ),
      ]),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: context.clr.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: context.clr.accent, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: context.clr.txtPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          Text(subtitle, style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
        ])),
        Icon(Icons.chevron_right_rounded, color: context.clr.txtMuted),
      ]),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
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
