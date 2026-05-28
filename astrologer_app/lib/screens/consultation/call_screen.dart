import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/astrologer.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../theme/app_theme.dart';
import 'chat_history_screen.dart';

const String _agoraAppId = 'e2e9d562aa754dcca16a5219e557b133';

class CallScreen extends StatefulWidget {
  final Astrologer astrologer;
  final String callType; // 'voice' or 'video'
  final String? consultationId;

  const CallScreen({super.key, required this.astrologer, required this.callType, this.consultationId});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final SocketService _socket = SocketService.instance;

  RtcEngine? _engine;
  String? _consultationId;
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isEnded = false;
  bool _dialogShown = false; // guard: show end dialog only once
  int _timerSeconds = 0;
  double _totalCharged = 0;
  int _remoteUid = 0;
  bool _remoteJoined = false;

  bool get _isVideo => widget.callType == 'video';

  @override
  void initState() {
    super.initState();
    _consultationId = widget.consultationId;
    _initSocket();
    // If consultationId already known (e.g. rejoining), start Agora immediately
    if (_consultationId != null) _initAgora(_consultationId!);
  }

  Future<void> _initAgora(String channelName) async {
    // Request permissions before initializing
    final perms = _isVideo
        ? [Permission.microphone, Permission.camera]
        : [Permission.microphone];
    final results = await perms.request();
    final denied = results.values.any((s) => s.isDenied || s.isPermanentlyDenied);
    if (denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone/Camera permission required for calls'), backgroundColor: context.clr.error),
        );
      }
      return;
    }

    try {
      final tokenData = await ApiService.getAgoraToken(channelName, uid: 2);
      final token = tokenData['data']?['token'] ?? tokenData['token'];
      const appId = _agoraAppId;

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(appId: appId));

      // Event handlers
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) setState(() => _isConnected = true);
          // Force speakerphone — default for audio calls is earpiece
          _engine?.setEnableSpeakerphone(_isSpeakerOn);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (mounted) setState(() { _remoteUid = remoteUid; _remoteJoined = true; });
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (!mounted) return;
          setState(() { _remoteJoined = false; _isEnded = true; });
          if (!_dialogShown) _cleanup().then((_) => _showEndDialog({}));
        },
        onLeaveChannel: (connection, stats) {},
      ));

      await _engine!.enableAudio();
      if (_isVideo) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      }

      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.joinChannel(
        token: token ?? '',
        channelId: channelName,
        uid: 2,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: _isVideo,
          autoSubscribeAudio: true,
          autoSubscribeVideo: _isVideo,
        ),
      );
    } catch (e) {
      debugPrint('Agora init error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call connection failed: $e'), backgroundColor: context.clr.error),
        );
      }
    }
  }

  void _initSocket() {
    _socket.connect(onConnected: _consultationId == null ? _requestConsultation : null);

    _socket.on('consultation_queued', (data) {
      final id = data['consultation_id'] as String?;
      if (id == null) return;
      setState(() => _consultationId = id);
      // Join Agora now so we're ready when astrologer accepts
      _initAgora(id);
    });

    _socket.on('consultation_started', (data) {
      if (mounted) setState(() => _isConnected = true);
    });

    _socket.on('billing_tick', (data) {
      if (mounted) setState(() {
        _timerSeconds = data['seconds'];
        _totalCharged = (data['amount_charged'] as num?)?.toDouble() ?? _totalCharged;
      });
    });

    _socket.on('consultation_ended', (data) {
      if (!mounted || _isEnded) return;
      setState(() => _isEnded = true);
      _cleanup().then((_) => _showEndDialog(data));
    });
  }

  void _requestConsultation() {
    _socket.requestConsultation(widget.astrologer.id, widget.callType);
  }

  Future<void> _toggleMute() async {
    await _engine?.muteLocalAudioStream(!_isMuted);
    setState(() => _isMuted = !_isMuted);
  }

  Future<void> _toggleCamera() async {
    await _engine?.muteLocalVideoStream(!_isCameraOff);
    setState(() => _isCameraOff = !_isCameraOff);
  }

  Future<void> _toggleSpeaker() async {
    await _engine?.setEnableSpeakerphone(!_isSpeakerOn);
    setState(() => _isSpeakerOn = !_isSpeakerOn);
  }

  Future<void> _endCall() async {
    if (_isEnded) return;
    setState(() => _isEnded = true);
    if (_consultationId != null) _socket.endConsultation(_consultationId!);
    await _cleanup();
    await _showEndDialog({});
  }

  Future<void> _cleanup() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
  }

  Future<void> _showEndDialog(Map data) async {
    if (!mounted || _dialogShown) return;
    _dialogShown = true;

    final viewChats = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: context.clr.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Call Ended', style: TextStyle(color: context.clr.txtPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(_isVideo ? Icons.videocam_off : Icons.call_end, color: context.clr.error, size: 48),
          const SizedBox(height: 12),
          Text('Duration: ${_formatTime(_timerSeconds)}', style: TextStyle(color: context.clr.txtSecondary)),
          Text('Total: ₹${_totalCharged.toStringAsFixed(2)}', style: TextStyle(color: context.clr.accent, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Back', style: TextStyle(color: context.clr.txtMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('View Chats'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (viewChats == true) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ChatHistoryScreen()));
    } else {
      Navigator.of(context).pop();
    }
  }

  String _formatTime(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _cleanup();
    _socket.off('consultation_queued');
    _socket.off('consultation_started');
    _socket.off('billing_tick');
    _socket.off('consultation_ended');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Remote video / voice background
        if (_isVideo && _remoteJoined && _engine != null && !_isEnded)
          Positioned.fill(child: AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine!,
              canvas: VideoCanvas(uid: _remoteUid),
              connection: RtcConnection(channelId: _consultationId ?? widget.astrologer.id),
            ),
          ))
        else
          _buildVoiceBackground(),

        // Local video PiP (video call only)
        if (_isVideo && _engine != null && !_isEnded)
          Positioned(top: 60, right: 16, child: Container(
            width: 100, height: 140,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: context.clr.accent.withValues(alpha: 0.5))),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isCameraOff
                  ? Container(color: Colors.black, child: const Icon(Icons.videocam_off, color: Colors.white54))
                  : AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
            ),
          )),

        // Top bar
        Positioned(top: 0, left: 0, right: 0, child: SafeArea(child: _buildTopBar())),

        // Bottom controls
        Positioned(bottom: 0, left: 0, right: 0, child: _buildControls()),
      ]),
    );
  }

  Widget _buildVoiceBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(center: Alignment.topCenter, radius: 1.5, colors: [context.clr.surface, context.clr.bg]),
      ),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          radius: 70,
          backgroundImage: widget.astrologer.avatarUrl != null ? NetworkImage(widget.astrologer.avatarUrl!) : null,
          backgroundColor: context.clr.accent.withValues(alpha: 0.2),
          child: widget.astrologer.avatarUrl == null
              ? Text(widget.astrologer.displayName[0], style: TextStyle(fontSize: 56, color: context.clr.accent, fontWeight: FontWeight.bold))
              : null,
        ),
        const SizedBox(height: 24),
        Text(widget.astrologer.displayName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_isConnected ? _formatTime(_timerSeconds) : 'Connecting…', style: TextStyle(color: context.clr.txtSecondary, fontSize: 16)),
        if (_isConnected) ...[
          const SizedBox(height: 8),
          Text('₹${_totalCharged.toStringAsFixed(2)} charged', style: TextStyle(color: context.clr.accent, fontSize: 13)),
        ],
      ])),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        GestureDetector(
          onTap: () {
            if (_isEnded) {
              Navigator.of(context).pop();
            } else {
              _endCall();
            }
          },
          child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18)),
        ),
        const Spacer(),
        if (_isConnected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Icon(Icons.timer, color: context.clr.accent, size: 14),
              const SizedBox(width: 4),
              Text(_formatTime(_timerSeconds), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_isConnected)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
              child: Text(
                '₹${_isVideo ? widget.astrologer.perMinuteRateVideo.toInt() : widget.astrologer.perMinuteRateCall.toInt()}/min',
                style: TextStyle(color: context.clr.accent, fontWeight: FontWeight.bold),
              ),
            ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ctrlBtn(Icons.mic_off, 'Mute', _isMuted, _toggleMute),
            if (_isVideo) _ctrlBtn(Icons.videocam_off, 'Camera', _isCameraOff, _toggleCamera),
            _ctrlBtn(Icons.volume_up, 'Speaker', !_isSpeakerOn, _toggleSpeaker),
            GestureDetector(
              onTap: _endCall,
              child: Column(children: [
                Container(width: 64, height: 64, decoration: BoxDecoration(color: context.clr.error, shape: BoxShape.circle), child: Icon(Icons.call_end, color: Colors.white, size: 28)),
                const SizedBox(height: 6),
                const Text('End', style: TextStyle(color: Colors.white, fontSize: 11)),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: isActive ? context.clr.accent.withValues(alpha: 0.8) : Colors.white12, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }
}
