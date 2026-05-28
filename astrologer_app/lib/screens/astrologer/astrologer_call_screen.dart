import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../theme/app_theme.dart';

const String _agoraAppId = 'e2e9d562aa754dcca16a5219e557b133';

class AstrologerCallScreen extends StatefulWidget {
  final String consultationId;
  final String userName;
  final String type;
  final VoidCallback onEnd;

  const AstrologerCallScreen({
    super.key,
    required this.consultationId,
    required this.userName,
    required this.type,
    required this.onEnd,
  });

  @override
  State<AstrologerCallScreen> createState() => _AstrologerCallScreenState();
}

class _AstrologerCallScreenState extends State<AstrologerCallScreen> {
  RtcEngine? _engine;
  int _elapsed = 0;
  bool _muted = false;
  bool _isEnded = false;
  bool _remoteJoined = false;
  int _remoteUid = 0;

  bool get _isVideo => widget.type == 'video';

  @override
  void initState() {
    super.initState();
    _setupSocket();
    _initAgora();
  }

  void _setupSocket() {
    final socket = SocketService.instance;
    socket.joinConsultation(widget.consultationId);
    socket.on('billing_tick', (data) {
      if (!mounted) return;
      final d = Map<String, dynamic>.from(data as Map);
      setState(() => _elapsed = d['seconds'] ?? _elapsed);
    });
    socket.on('consultation_ended', (data) {
      if (!mounted || _isEnded) return;
      setState(() => _isEnded = true);
      _cleanup();
      widget.onEnd();
    });
  }

  Future<void> _initAgora() async {
    final perms = _isVideo
        ? [Permission.microphone, Permission.camera]
        : [Permission.microphone];
    final results = await perms.request();
    if (results.values.any((s) => s.isDenied || s.isPermanentlyDenied)) return;

    try {
      // Astrologer uses uid: 1
      final tokenData = await ApiService.getAgoraToken(widget.consultationId, uid: 1);
      final token = tokenData['data']?['token'] ?? tokenData['token'];

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(appId: _agoraAppId));

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onUserJoined: (_, uid, __) {
          if (mounted) setState(() { _remoteUid = uid; _remoteJoined = true; });
        },
        onUserOffline: (_, uid, __) {
          if (mounted) setState(() => _remoteJoined = false);
        },
      ));

      if (_isVideo) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.enableAudio();
        await _engine!.setEnableSpeakerphone(true);
      }

      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.joinChannel(
        token: token ?? '',
        channelId: widget.consultationId,
        uid: 1,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: _isVideo,
        ),
      );
    } catch (e) {
      debugPrint('Agora init error (astrologer call): $e');
    }
  }

  Future<void> _cleanup() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
  }

  void _endCall() {
    if (_isEnded) return;
    setState(() => _isEnded = true);
    SocketService.instance.astrologerEndConsultation(widget.consultationId);
    _cleanup();
    widget.onEnd();
  }

  @override
  void dispose() {
    SocketService.instance.off('billing_tick');
    SocketService.instance.off('consultation_ended');
    _cleanup();
    super.dispose();
  }

  String get _durationText {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: const Color(0xFF0A0A0A),
        child: SafeArea(
          child: Stack(
            children: [
              // Remote video (video call only)
              if (_isVideo && _remoteJoined && _engine != null)
                Positioned.fill(
                  child: AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine!,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: widget.consultationId),
                    ),
                  ),
                ),

              // Local preview PiP (video call only)
              if (_isVideo && _engine != null)
                Positioned(
                  top: 16, right: 16,
                  child: Container(
                    width: 90, height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.clr.accent.withValues(alpha: 0.5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      ),
                    ),
                  ),
                ),

              // Main UI
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top info
                  Column(children: [
                    const SizedBox(height: 48),
                    if (!_isVideo || !_remoteJoined) ...[
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: context.clr.accent.withValues(alpha: 0.2),
                        child: Text(widget.userName[0].toUpperCase(),
                          style: TextStyle(color: context.clr.accent, fontSize: 36, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      Text(widget.userName,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                    ],
                    Text(_durationText,
                      style: TextStyle(color: context.clr.txtSecondary, fontSize: 16)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.clr.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(widget.type.toUpperCase(),
                        style: TextStyle(color: context.clr.success, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ]),

                  // Controls
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _callButton(
                          icon: _muted ? Icons.mic_off : Icons.mic,
                          color: _muted ? context.clr.error : Colors.white24,
                          onTap: () {
                            _engine?.muteLocalAudioStream(!_muted);
                            setState(() => _muted = !_muted);
                          },
                        ),
                        const SizedBox(width: 32),
                        _callButton(
                          icon: Icons.call_end,
                          color: context.clr.error,
                          size: 64,
                          onTap: _endCall,
                        ),
                        const SizedBox(width: 32),
                        _callButton(
                          icon: Icons.volume_up,
                          color: Colors.white24,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _callButton({required IconData icon, required Color color, double size = 52, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}
