import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/family_member.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  List<FamilyMember> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getFamilyMembers();
      if (mounted) setState(() { _members = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(FamilyMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Remove Member', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Remove ${member.name} from your family list?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteFamilyMember(member.id);
      _load();
    } catch (e) {
      if (mounted) _showSnack('Failed to remove member');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.surface));
  }

  void _openForm({FamilyMember? member}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FamilyMemberForm(
        existing: member,
        onSaved: (_) { Navigator.pop(context); _load(); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Family Members', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.orange,
        icon: const Icon(Icons.person_add, color: AppColors.white),
        label: const Text('Add Member', style: TextStyle(color: AppColors.white)),
      ),
      body: _isLoading
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.orange,
              child: _members.isEmpty ? _buildEmpty() : _buildList(),
            ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceLight,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 14, width: 140, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Container(height: 11, width: 80, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Container(height: 11, width: double.infinity, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 5),
              Container(height: 11, width: 120, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4))),
            ])),
            Column(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 8),
              Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 72, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text('No family members yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Tap + Add Member to get started', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 100),
      itemCount: _members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _MemberCard(
        member: _members[i],
        onEdit: () => _openForm(member: _members[i]),
        onDelete: () => _delete(_members[i]),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemberCard({required this.member, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _avatar(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(member.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15))),
                    if (member.sunSign != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(member.sunSign!, style: const TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (member.relationship != null)
                  Text(member.relationship!, style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                const SizedBox(height: 6),
                _infoRow(Icons.cake_outlined, _formatDate(member.dateOfBirth)),
                if (member.timeOfBirth != null) _infoRow(Icons.access_time_outlined, member.timeOfBirth!),
                if (member.birthPlace != null) _infoRow(Icons.location_on_outlined, member.birthPlace!),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    final initials = member.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.orange.withOpacity(0.15),
      child: Text(initials, style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day} ${_months[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
}

// ── Add / Edit bottom sheet ───────────────────────────────────────────────────

class _FamilyMemberForm extends StatefulWidget {
  final FamilyMember? existing;
  final void Function(FamilyMember) onSaved;

  const _FamilyMemberForm({this.existing, required this.onSaved});

  @override
  State<_FamilyMemberForm> createState() => _FamilyMemberFormState();
}

class _FamilyMemberFormState extends State<_FamilyMemberForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  String? _relationship;
  bool _isSaving = false;
  DateTime? _selectedDate;

  static const _relationships = ['Self', 'Spouse', 'Parent', 'Child', 'Sibling', 'Friend', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final m = widget.existing!;
      _nameCtrl.text = m.name;
      _dobCtrl.text = _formatDisplay(m.dateOfBirth);
      _selectedDate = DateTime.tryParse(m.dateOfBirth);
      _timeCtrl.text = m.timeOfBirth ?? '';
      _placeCtrl.text = m.birthPlace ?? '';
      _relationship = m.relationship;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _dobCtrl.dispose(); _timeCtrl.dispose(); _placeCtrl.dispose();
    super.dispose();
  }

  String _formatDisplay(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) { return raw; }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.orange, surface: AppColors.card),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobCtrl.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.orange, surface: AppColors.card),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _timeCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_relationship == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select relationship'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'date_of_birth': _selectedDate!.toIso8601String().split('T').first,
        'time_of_birth': _timeCtrl.text.trim(),
        'birth_place': _placeCtrl.text.trim(),
        'relationship': _relationship,
      };
      final FamilyMember result;
      if (widget.existing != null) {
        result = await ApiService.updateFamilyMember(widget.existing!.id, payload);
      } else {
        result = await ApiService.createFamilyMember(payload);
      }
      widget.onSaved(result);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(isEdit ? 'Edit Family Member' : 'Add Family Member',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            _field(
              controller: _nameCtrl,
              label: 'Name',
              hint: 'Enter full name',
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            _tapField(
              controller: _dobCtrl,
              label: 'Date of Birth *',
              hint: 'DD/MM/YYYY',
              icon: Icons.calendar_today_outlined,
              onTap: _pickDate,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Date of birth is required' : null,
            ),
            const SizedBox(height: 14),
            _tapField(
              controller: _timeCtrl,
              label: 'Time of Birth *',
              hint: 'HH:MM',
              icon: Icons.access_time_outlined,
              onTap: _pickTime,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Time of birth is required' : null,
            ),
            const SizedBox(height: 14),
            _field(
              controller: _placeCtrl,
              label: 'Place of Birth',
              hint: 'City, Country',
              icon: Icons.location_on_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Place of birth is required' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _relationship,
              decoration: _inputDecoration('Relationship', Icons.people_outline),
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary),
              hint: const Text('Select relationship', style: TextStyle(color: AppColors.textMuted)),
              items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _relationship = v),
              validator: (v) => v == null ? 'Relationship is required' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  disabledBackgroundColor: AppColors.orange.withOpacity(0.5),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                    : Text(isEdit ? 'Save Changes' : 'Add Member', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({required TextEditingController controller, required String label, required String hint, required IconData icon, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration(label, icon).copyWith(hintText: hint),
      validator: validator,
    );
  }

  Widget _tapField({required TextEditingController controller, required String label, required String hint, required IconData icon, required VoidCallback onTap, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration(label, icon).copyWith(hintText: hint),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.orange, width: 1.5)),
    );
  }
}
