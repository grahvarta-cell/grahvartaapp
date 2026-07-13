import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../api_service.dart';
import 'phone_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String phone;
  const DashboardScreen({super.key, required this.phone});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() { _loading = true; _error = null; _notFound = false; });
    try {
      final data = await ApiService.getApplicationStatus(widget.phone);
      if (data == null) {
        setState(() { _notFound = true; _loading = false; });
      } else {
        setState(() { _data = data; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Logout', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('agent_phone');
      await prefs.remove('agent_name');
      await prefs.remove('agent_token');
      await prefs.remove('agent_photo');
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PhoneScreen()), (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _data?['name'] as String? ?? '';
    final tokenNo = _data?['token_no'] as String? ?? '';
    final status = _data?['status'] as String? ?? 'pending';
    final photoUrl = _data?['profile_picture_url'] as String?;
    final adminNotes = _data?['admin_notes'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text('My Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchStatus,
          ),
        ],
      ),
      drawer: _buildDrawer(name, tokenNo, photoUrl, status),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _notFound
                  ? _buildNotFound()
                  : RefreshIndicator(
                  onRefresh: _fetchStatus,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(name, tokenNo),
                        const SizedBox(height: 24),
                        if (status == 'rejected') _buildRejected(adminNotes) else _buildStepper(status),
                        if (status == 'activated') ...[
                          const SizedBox(height: 16),
                          _buildActivatedBanner(_data?['welcome_email_sent'] == true),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader(String name, String tokenNo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha:0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha:0.8), fontSize: 13)),
            const SizedBox(height: 2),
            Text(name.isNotEmpty ? name : 'Applicant', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            if (tokenNo.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: tokenNo));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Token copied!'), duration: Duration(seconds: 1)));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha:0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.tag, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(tokenNo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
                    const SizedBox(width: 6),
                    const Icon(Icons.copy, color: Colors.white70, size: 12),
                  ]),
                ),
              ),
            ],
          ]),
        ),
        const Icon(Icons.star_rounded, color: Colors.white54, size: 52),
      ]),
    );
  }

  Widget _buildStepper(String status) {
    const steps = [
      _StepData(title: 'Shortlisting', activeMsg: 'Your profile is in pending state', doneMsg: 'Profile shortlisted successfully', icon: Icons.search_rounded),
      _StepData(title: 'Round 1 Interview', activeMsg: 'Please wait for our onboarding specialist call. He/she will inform you of your interview timing.', doneMsg: 'Round 1 interview completed', icon: Icons.phone_in_talk_rounded),
      _StepData(title: 'Round 2 Interview', activeMsg: 'Please wait for our onboarding specialist call. He/she will inform you of your interview timing.', doneMsg: 'Round 2 interview completed', icon: Icons.groups_rounded),
      _StepData(title: 'Profile Activation on Grahvarta', activeMsg: 'Please wait for Activation and Onboarding process.', doneMsg: 'Your profile is now live on Grahvarta!', icon: Icons.verified_rounded),
    ];

    final activeIndex = _statusToActiveIndex(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Application Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        ...List.generate(steps.length, (i) {
          final isDone = i < activeIndex;
          final isActive = i == activeIndex;
          final isLocked = i > activeIndex;
          return _buildStepCard(steps[i], i, isDone, isActive, isLocked, isLast: i == steps.length - 1);
        }),
      ],
    );
  }

  Widget _buildStepCard(_StepData step, int index, bool isDone, bool isActive, bool isLocked, {bool isLast = false}) {
    Color circleColor;
    Color borderColor;
    Widget circleChild;

    if (isDone) {
      circleColor = AppColors.success;
      borderColor = AppColors.success;
      circleChild = const Icon(Icons.check_rounded, color: Colors.white, size: 18);
    } else if (isActive) {
      circleColor = AppColors.primary;
      borderColor = AppColors.primary;
      circleChild = Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14));
    } else {
      circleColor = Colors.transparent;
      borderColor = AppColors.border;
      circleChild = Text('${index + 1}', style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 14));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 40, height: 40,
            decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle, border: Border.all(color: borderColor, width: 2),
              boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withValues(alpha:0.3), blurRadius: 10, spreadRadius: 2)] : null,
            ),
            child: Center(child: circleChild),
          ),
          if (!isLast)
            Container(width: 2, height: 50, color: isDone ? AppColors.success.withValues(alpha:0.4) : AppColors.border),
        ]),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withValues(alpha:0.10) : isLocked ? AppColors.surface : AppColors.success.withValues(alpha:0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isActive ? AppColors.primary.withValues(alpha:0.3) : isDone ? AppColors.success.withValues(alpha:0.2) : AppColors.border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(step.icon, size: 18, color: isActive ? AppColors.primary : isDone ? AppColors.success : AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(step.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isLocked ? AppColors.textMuted : AppColors.textPrimary)),
                  ),
                  if (isDone) const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                ]),
                const SizedBox(height: 8),
                Text(
                  isDone ? step.doneMsg : isActive ? step.activeMsg : 'Not reached yet',
                  style: TextStyle(fontSize: 13, height: 1.5, color: isActive ? AppColors.textPrimary : AppColors.textSecondary),
                ),
                if (isActive) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                    child: const Text('In Progress', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRejected(String? notes) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha:0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha:0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 22)),
          const SizedBox(width: 12),
          const Text('Application Not Progressed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error)),
        ]),
        const SizedBox(height: 12),
        const Text('Thank you for applying. Unfortunately we could not proceed with your application at this time.', style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Text(notes, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
        ],
      ]),
    );
  }

  Widget _buildActivatedBanner(bool emailSent) {
    return Column(children: [
      // Activation success card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          const Icon(Icons.verified_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Profile Activated!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              SizedBox(height: 4),
              Text('Welcome to the Grahvarta astrologer family.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
            ]),
          ),
        ]),
      ),

      // Email & login instructions card — always shown when activated
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(
              emailSent ? Icons.mark_email_read_outlined : Icons.email_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                emailSent ? 'Check Your Email' : 'Email Coming Soon',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                emailSent
                    ? 'You have received a mail with your login credentials. Login with Grahvarta Astrologer app and start receiving consultations.'
                    : 'You will receive a mail with your login credentials. Login with Grahvarta Astrologer app and start receiving consultations.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildNotFound() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.assignment_outlined, size: 64, color: AppColors.textMuted),
        const SizedBox(height: 16),
        const Text('No Application Found', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('We could not find an application for this phone number.\nPlease contact support or register again.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: _fetchStatus, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]),
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 16),
        const Text('Could not load status', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(_error ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: _fetchStatus, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]),
    ),
  );

  Widget _buildDrawer(String name, String tokenNo, String? photoUrl, String status) {
    return Drawer(
      backgroundColor: AppColors.card,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24, left: 24, right: 24, bottom: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white.withValues(alpha:0.2),
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage('https://api.grahvarta.com$photoUrl') as ImageProvider
                    : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'A', style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(height: 14),
              Text(name.isNotEmpty ? name : 'Agent', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              if (tokenNo.isNotEmpty)
                Row(children: [
                  const Icon(Icons.tag, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(tokenNo, style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace')),
                ]),
              const SizedBox(height: 6),
              _statusPill(status),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _DrawerItem(icon: Icons.contacts_outlined, label: 'Important Contacts', onTap: () => _showImportantContacts()),
                _DrawerItem(icon: Icons.mail_outline_rounded, label: 'Write to Us', onTap: () => _showWriteToUs()),
                _DrawerItem(icon: Icons.person_outline_rounded, label: 'Update Profile', onTap: () => Navigator.pop(context)),
                _DrawerItem(icon: Icons.help_outline_rounded, label: 'FAQ', onTap: () => _showFaq()),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          _DrawerItem(icon: Icons.logout_rounded, label: 'Logout', onTap: () { Navigator.pop(context); _logout(); }, color: AppColors.error),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    const labels = {
      'pending': 'Under Review',
      'shortlisted': 'Shortlisted',
      'round1': 'Round 1',
      'round2': 'Round 2',
      'activated': 'Active',
      'rejected': 'Not Progressed',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha:0.4)),
      ),
      child: Text(labels[status] ?? status, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  void _showImportantContacts() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Important Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _contactTile(Icons.support_agent_rounded, 'Onboarding Support', '+91 98765 43210'),
          _contactTile(Icons.mail_outline_rounded, 'Email Support', 'onboarding@grahvarta.com'),
          _contactTile(Icons.language_rounded, 'Website', 'www.grahvarta.com'),
        ]),
      ),
    );
  }

  Widget _contactTile(IconData icon, String title, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha:0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: AppColors.primary, size: 20)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14)),
    subtitle: Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
  );

  void _showWriteToUs() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Write to Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Send us a message and we\'ll get back to you.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          TextField(maxLines: 4, decoration: InputDecoration(hintText: 'Type your message here...', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message sent!'))); }, child: const Text('Send Message'))),
        ]),
      ),
    );
  }

  void _showFaq() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          children: [
            const Text('FAQ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            ...[
              ('How long does the selection process take?', 'The entire process typically takes 7–14 business days. Each stage is reviewed carefully before progressing.'),
              ('What does the token number mean?', 'Your token number (e.g. GRH-01001) is your unique application reference. Use it in all communications with our team.'),
              ('What happens after profile activation?', 'Once activated, your profile will be visible to users on the Grahvarta platform and you can start receiving consultation requests.'),
              ('Who conducts the interview rounds?', 'Our onboarding specialist will call you on the number you registered with to schedule and conduct the interview.'),
            ].map((faq) => _FaqItem(q: faq.$1, a: faq.$2)),
          ],
        ),
      ),
    );
  }

  int _statusToActiveIndex(String status) {
    switch (status) {
      case 'shortlisted': return 1;
      case 'round1':      return 2;
      case 'round2':      return 3;
      case 'activated':   return 4;
      default:            return 0; // pending
    }
  }
}

class _StepData {
  final String title, activeMsg, doneMsg;
  final IconData icon;
  const _StepData({required this.title, required this.activeMsg, required this.doneMsg, required this.icon});
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
    title: Text(label, style: TextStyle(color: color ?? AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
    trailing: color == null ? const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18) : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
  );
}

class _FaqItem extends StatelessWidget {
  final String q, a;
  const _FaqItem({required this.q, required this.a});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(q, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14)),
      const SizedBox(height: 8),
      Text(a, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
    ]),
  );
}
