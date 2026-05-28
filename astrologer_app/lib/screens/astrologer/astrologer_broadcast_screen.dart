import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/astrologer.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../theme/app_theme.dart';

const String _agoraAppId = 'e2e9d562aa754dcca16a5219e557b133';

class AstrologerBroadcastScreen extends StatefulWidget {
  final LiveSession session;

  const AstrologerBroadcastScreen({super.key, required this.session});

  @override
  State<AstrologerBroadcastScreen> createState() => _AstrologerBroadcastScreenState();
}

class _AstrologerBroadcastScreenState extends State<AstrologerBroadcastScreen> {
  RtcEngine? _engine;
  bool _joined = false;
  bool _muted = false;
  bool _cameraOff = false;
  int _viewers = 0;
  double _totalTips = 0;
  final List<Map<String, dynamic>> _chatMessages = [];
  final _chatCtrl = TextEditingController();
  int _elapsed = 0;
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    _initBroadcast();
    _setupSocket();
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    _chatCtrl.dispose();
    SocketService.instance.leaveLive(widget.session.id);
    SocketService.instance.off('viewer_count');
    SocketService.instance.off('live_chat_message');
    SocketService.instance.off('new_tip');
    super.dispose();
  }

  void _setupSocket() {
    final socket = SocketService.instance;

    // Register listeners BEFORE joining so the immediate viewer_count isn't missed
    socket.on('viewer_count', (data) {
      if (!mounted) return;
      setState(() => _viewers = (data as Map)['count'] ?? _viewers);
    });
    socket.on('live_chat_message', (data) {
      if (!mounted) return;
      final d = Map<String, dynamic>.from(data as Map);
      // Normalise field: backend sends 'user', ensure 'user_name' for display
      if (!d.containsKey('user_name')) d['user_name'] = d['user'];
      setState(() => _chatMessages.add(d));
    });
    socket.on('new_tip', (data) {
      if (!mounted) return;
      final d = Map<String, dynamic>.from(data as Map);
      final amount = double.tryParse(d['amount']?.toString() ?? '0') ?? 0;
      setState(() => _totalTips += amount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💰 ${d['user'] ?? 'Someone'} tipped ₹${amount.toStringAsFixed(0)}!'),
          backgroundColor: context.clr.success,
          duration: const Duration(seconds: 3),
        ),
      );
    });

    // Join after listeners are set up
    socket.joinLive(widget.session.id);
  }

  Future<void> _initBroadcast() async {
    // Request permissions
    final results = await [Permission.microphone, Permission.camera].request();
    final denied = results.values.any((s) => s.isDenied || s.isPermanentlyDenied);
    if (denied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera & Microphone permission required'), backgroundColor: context.clr.error),
      );
      return;
    }

    try {
      // Get Agora token using session id as channel
      final tokenData = await ApiService.getAgoraToken(widget.session.id, uid: 1);
      final token = tokenData['data']?['token'] ?? tokenData['token'];

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(appId: _agoraAppId));

      // Set broadcaster role
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      await _engine!.startPreview();

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) setState(() => _joined = true);
        },
        onLeaveChannel: (connection, stats) {
          if (mounted) setState(() => _joined = false);
        },
      ));

      await _engine!.joinChannel(
        token: token ?? '',
        channelId: widget.session.id,
        uid: 1,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start broadcast: $e'), backgroundColor: context.clr.error),
        );
      }
    }
  }

  Future<void> _endSession() async {
    setState(() => _ending = true);
    try {
      await ApiService.endLiveSession(widget.session.id);
      await _engine?.leaveChannel();
      SocketService.instance.emit('end_broadcast', {'session_id': widget.session.id});
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: context.clr.error),
        );
        setState(() => _ending = false);
      }
    }
  }

  void _sendChat() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    SocketService.instance.sendLiveChat(widget.session.id, text);
    _chatCtrl.clear();
  }

  String get _elapsedText {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Local video preview
          if (_joined && _engine != null && !_cameraOff)
            AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine!,
                canvas: const VideoCanvas(uid: 0),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: Center(
                child: _joined
                    ? const Icon(Icons.videocam_off, color: Colors.white54, size: 64)
                    : CircularProgressIndicator(color: context.clr.accent),
              ),
            ),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    // Live badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: context.clr.error, borderRadius: BorderRadius.circular(6)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Text(_elapsedText, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    const Spacer(),
                    // Viewer count
                    Row(children: [
                      const Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text('$_viewers', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ]),
                    const SizedBox(width: 12),
                    // Tips
                    Row(children: [
                      const Icon(Icons.monetization_on_outlined, color: Color(0xFFFFD700), size: 16),
                      const SizedBox(width: 4),
                      Text('₹${_totalTips.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13)),
                    ]),
                  ],
                ),
              ),
            ),
          ),

          // Chat messages
          Positioned(
            bottom: 100, left: 12, right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: _chatMessages.reversed.take(5).toList().reversed.map((m) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: '${m['user_name'] ?? 'User'}: ',
                        style: TextStyle(color: context.clr.accent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: m['message'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ]),
                  ),
                ),
              ).toList(),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    // Chat input
                    Expanded(
                      child: TextField(
                        controller: _chatCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Say something...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.15),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendChat(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mute
                    _ctrlBtn(
                      icon: _muted ? Icons.mic_off : Icons.mic,
                      color: _muted ? context.clr.error : Colors.white24,
                      onTap: () {
                        setState(() => _muted = !_muted);
                        _engine?.muteLocalAudioStream(_muted);
                      },
                    ),
                    const SizedBox(width: 8),
                    // Camera toggle
                    _ctrlBtn(
                      icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                      color: _cameraOff ? context.clr.error : Colors.white24,
                      onTap: () {
                        setState(() => _cameraOff = !_cameraOff);
                        _engine?.muteLocalVideoStream(_cameraOff);
                      },
                    ),
                    const SizedBox(width: 8),
                    // End
                    _ctrlBtn(
                      icon: Icons.call_end,
                      color: context.clr.error,
                      onTap: _ending ? null : _endSession,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn({required IconData icon, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
