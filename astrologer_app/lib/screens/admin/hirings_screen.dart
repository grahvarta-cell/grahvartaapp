import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

const _base = 'https://api.grahvarta.com/api';
const _storage = FlutterSecureStorage();
const _tokenKey = 'admin_token';

// ─── API helpers ─────────────────────────────────────────────────────────────

Future<String> _adminLogin(String email, String password) async {
  final r = await http.post(
    Uri.parse('$_base/admin/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  final body = jsonDecode(r.body);
  if (r.statusCode != 200) throw body['message'] ?? 'Login failed';
  return body['data']['token'] as String;
}

Future<Map<String, dynamic>> _fetchHirings(String token, {String? status, int page = 1}) async {
  final params = {'page': '$page', 'limit': '20', if (status != null && status != 'all') 'status': status};
  final uri = Uri.parse('$_base/admin/hirings').replace(queryParameters: params);
  final r = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
  final body = jsonDecode(r.body);
  if (r.statusCode != 200) throw body['message'] ?? 'Fetch failed';
  return body as Map<String, dynamic>;
}

Future<void> _updateStatus(String token, String id, String status, String notes) async {
  final r = await http.patch(
    Uri.parse('$_base/admin/hirings/$id'),
    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    body: jsonEncode({'status': status, 'admin_notes': notes}),
  );
  if (r.statusCode != 200) throw jsonDecode(r.body)['message'] ?? 'Update failed';
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class AdminHiringsScreen extends StatefulWidget {
  const AdminHiringsScreen({super.key});
  @override
  State<AdminHiringsScreen> createState() => _AdminHiringsScreenState();
}

class _AdminHiringsScreenState extends State<AdminHiringsScreen> {
  String? _token;
  bool _checkingToken = true;

  @override
  void initState() {
    super.initState();
    _storage.read(key: _tokenKey).then((t) {
      if (mounted) setState(() { _token = t; _checkingToken = false; });
    });
  }

  void _onLogin(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    setState(() => _token = token);
  }

  void _logout() async {
    await _storage.delete(key: _tokenKey);
    setState(() => _token = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingToken) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.orange)));
    if (_token == null) return _LoginScreen(onLogin: _onLogin);
    return _HiringsListScreen(token: _token!, onLogout: _logout);
  }
}

// ─── Login ────────────────────────────────────────────────────────────────────

class _LoginScreen extends StatefulWidget {
  final void Function(String token) onLogin;
  const _LoginScreen({required this.onLogin});
  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await _adminLogin(_emailCtrl.text.trim(), _passCtrl.text);
      widget.onLogin(token);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.admin_panel_settings, size: 64, color: AppColors.orange),
          const SizedBox(height: 16),
          const Text('Admin Panel', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 32),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Admin Email', prefixIcon: Icon(Icons.email_outlined)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign In'),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── List ─────────────────────────────────────────────────────────────────────

class _HiringsListScreen extends StatefulWidget {
  final String token;
  final VoidCallback onLogout;
  const _HiringsListScreen({required this.token, required this.onLogout});
  @override
  State<_HiringsListScreen> createState() => _HiringsListScreenState();
}

class _HiringsListScreenState extends State<_HiringsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _filters = ['all', 'pending', 'acknowledged', 'denied'];
  final _labels = ['All', 'Pending', 'Acknowledged', 'Denied'];
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() { if (!_tabs.indexIsChanging) _load(); });
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final filter = _filters[_tabs.index];
      final data = await _fetchHirings(widget.token, status: filter);
      setState(() {
        _items = data['data'] as List;
        _total = data['total'] as int? ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Agent Hirings ($_total)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(icon: const Icon(Icons.logout, color: AppColors.error), onPressed: widget.onLogout),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.orange,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.orange,
          isScrollable: true,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : _items.isEmpty
                  ? const Center(child: Text('No applications', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (_, i) => _HiringCard(item: _items[i], token: widget.token, onRefresh: _load),
                    ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _HiringCard extends StatelessWidget {
  final dynamic item;
  final String token;
  final VoidCallback onRefresh;
  const _HiringCard({required this.item, required this.token, required this.onRefresh});

  Color _statusColor(String s) {
    switch (s) {
      case 'acknowledged': return AppColors.success;
      case 'denied': return AppColors.error;
      default: return AppColors.orange;
    }
  }

  String _fmtDate(String? d) {
    if (d == null) return '-';
    try { return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(d).toLocal()); }
    catch (_) { return d; }
  }

  List<String> _parseJson(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.cast<String>();
    try { return (jsonDecode(v.toString()) as List).cast<String>(); }
    catch (_) { return []; }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DetailSheet(item: item, token: token, onRefresh: () { Navigator.pop(context); onRefresh(); }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = item['status'] as String? ?? 'pending';
    final skills = _parseJson(item['skills']);

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.orange.withValues(alpha:0.15),
              backgroundImage: item['profile_picture_url'] != null ? NetworkImage('https://api.grahvarta.com${item['profile_picture_url']}') : null,
              child: item['profile_picture_url'] == null ? const Icon(Icons.person, color: AppColors.orange) : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['name'] ?? 'Unknown', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(item['phone'] ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _statusColor(status).withValues(alpha:0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(status.toUpperCase(), style: TextStyle(color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ]),
          const SizedBox(height: 10),
          _row(Icons.email_outlined, item['email'] ?? '-'),
          _row(Icons.phone_android, '${item['phone_type'] ?? '-'} · ${item['works_online'] == true ? 'Online' : 'Offline'} · ${item['hours_available'] ?? 0}h/day'),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4,
              children: skills.take(4).map((s) => Chip(
                label: Text(s, style: const TextStyle(fontSize: 10)),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AppColors.orange.withValues(alpha:0.1),
                side: BorderSide.none,
              )).toList()
                ..addAll(skills.length > 4 ? [Chip(label: Text('+${skills.length - 4}', style: const TextStyle(fontSize: 10)), padding: const EdgeInsets.symmetric(horizontal: 2), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, backgroundColor: AppColors.border, side: BorderSide.none)] : []),
            ),
          ],
          const SizedBox(height: 8),
          Text(_fmtDate(item['created_at'] as String?), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(children: [
      Icon(icon, size: 13, color: AppColors.textMuted),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
    ]),
  );
}

// ─── Detail sheet ─────────────────────────────────────────────────────────────

class _DetailSheet extends StatefulWidget {
  final dynamic item;
  final String token;
  final VoidCallback onRefresh;
  const _DetailSheet({required this.item, required this.token, required this.onRefresh});
  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl.text = widget.item['admin_notes'] ?? '';
  }

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  Future<void> _update(String status) async {
    setState(() => _saving = true);
    try {
      await _updateStatus(widget.token, widget.item['id'] as String, status, _notesCtrl.text.trim());
      widget.onRefresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      setState(() => _saving = false);
    }
  }

  List<String> _parseJson(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.cast<String>();
    try { return (jsonDecode(v.toString()) as List).cast<String>(); } catch (_) { return []; }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final langs = _parseJson(item['languages']);
    final skills = _parseJson(item['skills']);
    final status = item['status'] as String? ?? 'pending';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // Header
          Row(children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.orange.withValues(alpha:0.15),
              backgroundImage: item['profile_picture_url'] != null ? NetworkImage('https://api.grahvarta.com${item['profile_picture_url']}') : null,
              child: item['profile_picture_url'] == null ? const Icon(Icons.person, color: AppColors.orange, size: 30) : null,
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['name'] ?? 'Unknown', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(item['phone'] ?? '', style: const TextStyle(color: AppColors.textMuted)),
            ])),
          ]),
          const SizedBox(height: 20),

          _infoTile('Email', item['email'] ?? '-'),
          _infoTile('Gender', item['gender'] ?? '-'),
          _infoTile('Date of Birth', item['dob'] ?? '-'),
          _infoTile('Phone Type', item['phone_type'] ?? '-'),
          _infoTile('Works Online', item['works_online'] == true ? 'Yes' : 'No'),
          _infoTile('Hours/Day', '${item['hours_available'] ?? 0}'),

          if (langs.isNotEmpty) ...[
            const SizedBox(height: 12),
            _label('Languages'),
            Wrap(spacing: 6, runSpacing: 6,
              children: langs.map((l) => Chip(label: Text(l, style: const TextStyle(fontSize: 11)), backgroundColor: AppColors.card, side: const BorderSide(color: AppColors.border))).toList()),
          ],

          if (skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            _label('Skills'),
            Wrap(spacing: 6, runSpacing: 6,
              children: skills.map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 11, color: AppColors.orange)), backgroundColor: AppColors.orange.withValues(alpha:0.1), side: BorderSide.none)).toList()),
          ],

          const SizedBox(height: 20),
          _label('Admin Notes'),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Add notes about this applicant...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.orange, width: 1.5)),
            ),
          ),

          const SizedBox(height: 24),
          if (_saving)
            const Center(child: CircularProgressIndicator(color: AppColors.orange))
          else
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: status == 'denied' ? null : () => _update('denied'),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Deny'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: status == 'acknowledged' ? null : () => _update('acknowledged'),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Acknowledge'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
        ]),
      ),
    );
  }

  Widget _infoTile(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );

  Widget _label(String t) => Text(t, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14));
}
