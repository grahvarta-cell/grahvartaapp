import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/socket_service.dart';
import '../../theme/app_theme.dart';
import 'astrologer_dashboard_screen.dart';
import 'astrologer_live_screen.dart';
import 'astrologer_community_screen.dart';
import 'astrologer_chat_history_screen.dart';
import 'astrologer_pending_screen.dart';
import 'astrologer_consultations_screen.dart';
import 'astrologer_chat_screen.dart';
import 'astrologer_call_screen.dart';

class AstrologerMainScreen extends StatefulWidget {
  const AstrologerMainScreen({super.key});

  @override
  State<AstrologerMainScreen> createState() => _AstrologerMainScreenState();
}

class _AstrologerMainScreenState extends State<AstrologerMainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Map<String, dynamic>? _incomingRequest;
  Map<String, dynamic>? _activeCall;
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  late final AnimationController _overlayCtrl;
  late final Animation<double> _overlayScale;
  late final Animation<double> _overlayFade;
  Timer? _heartbeatTimer;

  final List<Widget> _screens = const [
    AstrologerDashboardScreen(),
    AstrologerConsultationsScreen(),
    AstrologerChatHistoryScreen(),
    AstrologerLiveScreen(),
    AstrologerCommunityScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _overlayCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _overlayScale = CurvedAnimation(parent: _overlayCtrl, curve: Curves.elasticOut);
    _overlayFade = CurvedAnimation(parent: _overlayCtrl, curve: Curves.easeOut);
    _setupSocket();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _overlayCtrl.dispose();
    SocketService.instance.off('new_consultation_request');
    _ringtonePlayer.dispose();
    super.dispose();
  }

  void _setupSocket() {
    final socket = SocketService.instance;
    socket.connect(role: 'astrologer');
    socket.on('new_consultation_request', (data) {
      if (!mounted) return;
      setState(() => _incomingRequest = Map<String, dynamic>.from(data as Map));
      _overlayCtrl.forward(from: 0);
      _playRingtone();
    });

    // Re-emit set_role every 30s so server map stays fresh after restarts
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (SocketService.instance.isConnected) {
        SocketService.instance.emit('set_role', {'role': 'astrologer'});
      }
    });
  }

  Future<void> _playRingtone() async {
    try {
      await _ringtonePlayer.setAsset('assets/images/ringtone.mp3');
      await _ringtonePlayer.setLoopMode(LoopMode.one);
      await _ringtonePlayer.play();
    } catch (_) {}
  }

  Future<void> _stopRingtone() async {
    try {
      await _ringtonePlayer.stop();
    } catch (_) {}
  }

  void _acceptRequest() {
    if (_incomingRequest == null) return;
    _stopRingtone();
    final req = _incomingRequest!;
    SocketService.instance.acceptConsultation(req['consultation_id']);
    setState(() => _incomingRequest = null);

    final type = req['type'] ?? 'chat';
    if (type == 'chat') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => AstrologerChatScreen(
          consultationId: req['consultation_id'],
          userName: req['user']?['name'] ?? 'User',
          userId: req['user']?['id']?.toString(),
        ),
      ));
    } else {
      setState(() => _activeCall = req);
    }
  }

  void _declineRequest() {
    if (_incomingRequest == null) return;
    _stopRingtone();
    SocketService.instance.rejectConsultation(_incomingRequest!['consultation_id']);
    setState(() => _incomingRequest = null);
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.clr.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Exit App', style: TextStyle(color: context.clr.txtPrimary)),
        content: Text('Are you sure you want to exit?', style: TextStyle(color: context.clr.txtSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: context.clr.txtSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit')),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.astrologerProfile;

    if (profile != null && !profile.isApproved) {
      return const AstrologerPendingScreen();
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          Scaffold(
            body: IndexedStack(index: _currentIndex, children: _screens),
            bottomNavigationBar: _buildBottomNav(),
          ),
          if (_incomingRequest != null) _buildIncomingRequestOverlay(),
          if (_activeCall != null) AstrologerCallScreen(
            consultationId: _activeCall!['consultation_id'],
            userName: _activeCall!['user']?['name'] ?? 'User',
            type: _activeCall!['type'] ?? 'voice',
            onEnd: () => setState(() => _activeCall = null),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: context.clr.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(icon: Icons.dashboard_rounded, index: 0, label: 'Dashboard'),
              _navItem(icon: Icons.history_rounded, index: 1, label: 'Sessions'),
              _navItem(icon: Icons.chat_bubble_outline_rounded, index: 2, label: 'Chats'),
              _navItem(icon: Icons.live_tv_rounded, index: 3, label: 'Live'),
              _navItem(icon: Icons.people_rounded, index: 4, label: 'Community'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required int index, required String label}) {
    final isSelected = index == _currentIndex;

    final showBadge = _incomingRequest != null && (index == 0 || index == 1);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? context.clr.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: isSelected ? Colors.white : context.clr.txtMuted, size: 22),
              if (isSelected) ...[
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ]),
          ),
          if (showBadge)
            Positioned(
              top: 4, right: 4,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: context.clr.error, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequestOverlay() {
    final req = _incomingRequest!;
    final type = req['type'] ?? 'chat';
    final rawName = req['user']?['name']?.toString() ?? 'User';
    final userName = rawName.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ');
    final rate = req['rate'] ?? 0;

    IconData icon;
    switch (type) {
      case 'voice': icon = Icons.phone_rounded; break;
      case 'video': icon = Icons.videocam_rounded; break;
      default: icon = Icons.chat_bubble_rounded;
    }

    return Positioned.fill(
      child: FadeTransition(
        opacity: _overlayFade,
        child: Material(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: ScaleTransition(
            scale: _overlayScale,
            child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: context.clr.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.clr.accent.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: context.clr.accent.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(icon, color: context.clr.accent, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Incoming ${type.toUpperCase()} Consultation',
                  style: TextStyle(color: context.clr.txtMuted, fontSize: 11, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Text(userName, style: TextStyle(color: context.clr.txtPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('₹$rate/min', style: TextStyle(color: context.clr.txtSecondary, fontSize: 14)),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _declineRequest,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Decline'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.clr.error.withValues(alpha: 0.2),
                        foregroundColor: context.clr.error,
                        side: BorderSide(color: context.clr.error.withValues(alpha: 0.5)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _acceptRequest,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.clr.success.withValues(alpha: 0.2),
                        foregroundColor: context.clr.success,
                        side: BorderSide(color: context.clr.success.withValues(alpha: 0.5)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          ),
        ),
        ),
      ),
    );
  }
}
