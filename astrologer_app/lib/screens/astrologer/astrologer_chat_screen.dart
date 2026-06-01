import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../theme/app_theme.dart';

class AstrologerChatScreen extends StatefulWidget {
  final String consultationId;
  final String userName;
  final String? userId;

  const AstrologerChatScreen({super.key, required this.consultationId, required this.userName, this.userId});

  @override
  State<AstrologerChatScreen> createState() => _AstrologerChatScreenState();
}

class _AstrologerChatScreenState extends State<AstrologerChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _isEnded = false;
  bool _isPeerTyping = false;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _setupSocket();
  }

  @override
  void dispose() {
    SocketService.instance.off('new_message');
    SocketService.instance.off('billing_tick');
    SocketService.instance.off('peer_typing');
    SocketService.instance.off('consultation_ended');
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      // Load old cross-session history first (if userId is known)
      if (widget.userId != null && widget.userId!.isNotEmpty) {
        try {
          final data = await ApiService.getAstrologerUserMessages(widget.userId!);
          final old = List<dynamic>.from(data['messages'] ?? []);
          if (old.isNotEmpty && mounted) {
            setState(() {
              _messages.addAll(old.map((m) => Map<String, dynamic>.from(m as Map)));
              _messages.add({'sender_type': 'system', 'content': '─── Current session ───', 'created_at': DateTime.now().toIso8601String()});
            });
          }
        } catch (_) {}
      }

      final msgs = await ApiService.getAstrologerConsultationMessages(widget.consultationId);
      if (mounted) {
        setState(() {
          _messages.addAll(msgs.map((m) => Map<String, dynamic>.from(m as Map)));
          _loading = false;
        });
        _scrollBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setupSocket() {
    final socket = SocketService.instance;
    // Join the consultation room so we receive new_message and billing_tick
    socket.joinConsultation(widget.consultationId);
    socket.on('new_message', (data) {
      if (!mounted) return;
      final msg = Map<String, dynamic>.from(data as Map);
      if (msg['sender_type'] == 'astrologer') return;
      final normalized = {...msg, 'type': msg['message_type'] ?? msg['type'] ?? 'text'};
      setState(() => _messages.add(normalized));
      _scrollBottom();
    });
    socket.on('billing_tick', (data) {
      if (!mounted) return;
      final d = Map<String, dynamic>.from(data as Map);
      setState(() => _elapsed = d['seconds'] ?? _elapsed);
    });
    socket.on('peer_typing', (data) {
      if (!mounted) return;
      setState(() => _isPeerTyping = (data as Map)['is_typing'] == true);
    });
    socket.on('consultation_ended', (data) {
      if (!mounted || _isEnded) return;
      setState(() => _isEnded = true);
      final d = Map<String, dynamic>.from(data as Map);
      _showEndDialog(d);
    });
  }

  void _showEndDialog(Map<String, dynamic> data) {
    final duration = data['duration'] ?? _elapsed;
    final total = double.tryParse(data['total_amount']?.toString() ?? '0') ?? 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: context.clr.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Session Ended', style: TextStyle(color: context.clr.txtPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline, color: context.clr.success, size: 48),
          const SizedBox(height: 12),
          Text('Duration: ${_formatTime(duration is int ? duration : (duration as num).toInt())}',
              style: TextStyle(color: context.clr.txtSecondary)),
          const SizedBox(height: 4),
          Text('Earned: ₹${(total * 0.8).toStringAsFixed(2)}',
              style: TextStyle(color: context.clr.success, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  void _sendMessage() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _isEnded) return;
    SocketService.instance.sendTypingStop(widget.consultationId);
    SocketService.instance.sendMessage(widget.consultationId, text);
    setState(() => _messages.add({'sender_type': 'astrologer', 'content': text, 'created_at': DateTime.now().toIso8601String()}));
    _ctrl.clear();
    _scrollBottom();
  }

  CameraDevice _cameraDevice = CameraDevice.front;

  void _showImageOptions() {
    if (_isEnded) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const Text('Send Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(backgroundColor: context.clr.accent, child: const Icon(Icons.photo_library, color: Colors.white)),
                title: const Text('Choose from Gallery'),
                onTap: () { Navigator.pop(context); _pickAndSendImage(ImageSource.gallery); },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: context.clr.accent,
                  child: Icon(_cameraDevice == CameraDevice.front ? Icons.camera_front : Icons.camera_rear, color: Colors.white),
                ),
                title: Text(_cameraDevice == CameraDevice.front ? 'Take Selfie (Front Camera)' : 'Take Photo (Rear Camera)'),
                trailing: IconButton(
                  tooltip: 'Switch Camera',
                  icon: Icon(Icons.switch_camera, color: context.clr.accent),
                  onPressed: () {
                    setSheet(() => _cameraDevice = _cameraDevice == CameraDevice.front ? CameraDevice.rear : CameraDevice.front);
                    setState(() {});
                  },
                ),
                onTap: () { Navigator.pop(context); _pickAndSendImage(ImageSource.camera); },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      preferredCameraDevice: source == ImageSource.camera ? _cameraDevice : CameraDevice.rear,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    final localId = 'uploading_${DateTime.now().millisecondsSinceEpoch}';
    setState(() => _messages.add({
      'id': localId, 'sender_type': 'astrologer', 'content': '', 'type': 'image_uploading',
      'created_at': DateTime.now().toIso8601String(),
    }));
    _scrollBottom();

    try {
      final url = await ApiService.uploadChatImage(File(picked.path));
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == localId);
        if (idx != -1) _messages[idx] = {'id': localId, 'sender_type': 'astrologer', 'content': url, 'type': 'image', 'created_at': DateTime.now().toIso8601String()};
      });
      SocketService.instance.sendMessage(widget.consultationId, url, type: 'image');
      _scrollBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == localId);
        if (idx != -1) _messages[idx] = {'sender_type': 'astrologer', 'content': '⚠️ Image failed to send', 'type': 'text', 'created_at': DateTime.now().toIso8601String()};
      });
    }
  }

  void _openFullscreen(String url) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _FullscreenImageScreen(url: url)));
  }

  void _endConsultation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.clr.card,
        title: Text('End Consultation', style: TextStyle(color: context.clr.txtPrimary)),
        content: Text('Are you sure you want to end this consultation?', style: TextStyle(color: context.clr.txtSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: context.clr.txtSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (!_isEnded) {
                setState(() => _isEnded = true);
                SocketService.instance.astrologerEndConsultation(widget.consultationId);
              }
            },
            child: const Text('End'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: context.clr.accent.withValues(alpha: 0.2),
          child: Text(widget.userName[0].toUpperCase(), style: TextStyle(color: context.clr.accent, fontSize: 10)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(18)),
          child: Row(children: List.generate(3, (i) => Container(
            margin: EdgeInsets.only(right: i < 2 ? 3 : 0),
            width: 6, height: 6,
            decoration: BoxDecoration(color: context.clr.txtMuted, shape: BoxShape.circle),
          ))),
        ),
      ]),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.clr.surface,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName, style: TextStyle(color: context.clr.txtPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            if (_elapsed > 0)
              Text('Duration: ${_formatTime(_elapsed)}', style: TextStyle(color: context.clr.accent, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _endConsultation,
            icon: Icon(Icons.call_end, color: context.clr.error, size: 18),
            label: Text('End', style: TextStyle(color: context.clr.error)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isEnded
                ? Center(child: Text('Session ended', style: TextStyle(color: context.clr.txtMuted)))
                : _loading
                ? _buildShimmer()
                : _messages.isEmpty
                    ? Center(child: Text('No messages yet', style: TextStyle(color: context.clr.txtMuted)))
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _AnimatedBubble(
                          key: ValueKey(_messages[i]['id'] ?? _messages[i]['created_at'] ?? i),
                          child: _buildMessage(_messages[i]),
                        ),
                      ),
          ),
          if (_isPeerTyping) _buildTypingIndicator(),
          if (!_isEnded) _buildInput(),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: context.clr.card,
      highlightColor: context.clr.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (_, i) {
          final isMe = i % 3 != 0;
          final width = (i % 3 == 0 ? 200.0 : i % 3 == 1 ? 140.0 : 240.0);
          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              width: width,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final senderType = msg['sender_type'] ?? msg['sender_role'] ?? '';
    if (senderType == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(20)),
          child: Text(msg['content'] ?? msg['message'] ?? '', style: TextStyle(color: context.clr.txtMuted, fontSize: 12), textAlign: TextAlign.center),
        )),
      );
    }
    final isMe = senderType == 'astrologer';
    final msgType = msg['type'] ?? 'text';
    final isImage = msgType == 'image';
    final isUploading = msgType == 'image_uploading';
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );

    Widget content;
    if (isUploading) {
      content = Container(
        width: 180, height: 140,
        decoration: BoxDecoration(color: isMe ? context.clr.accent : context.clr.card, borderRadius: borderRadius),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (isImage) {
      final url = msg['content'] ?? msg['message'] ?? '';
      content = GestureDetector(
        onTap: () => _openFullscreen(url),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Image.network(
            url, width: 200, height: 160, fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Container(width: 200, height: 160, color: context.clr.card,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
            errorBuilder: (_, __, ___) => Container(
              width: 200, height: 80,
              decoration: BoxDecoration(color: context.clr.card, borderRadius: borderRadius),
              child: Icon(Icons.broken_image, color: context.clr.txtMuted),
            ),
          ),
        ),
      );
    } else {
      content = Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(color: isMe ? context.clr.accent : context.clr.card, borderRadius: borderRadius),
        child: Text(msg['content'] ?? msg['message'] ?? '', style: TextStyle(color: isMe ? Colors.white : context.clr.txtPrimary, fontSize: 14)),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(padding: const EdgeInsets.only(bottom: 8), child: content),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(left: 8, right: 16, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
      color: context.clr.surface,
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: context.clr.txtMuted),
          onPressed: _showImageOptions,
        ),
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: TextStyle(color: context.clr.txtPrimary),
            decoration: InputDecoration(
              hintText: 'Type a message…',
              hintStyle: TextStyle(color: context.clr.txtMuted),
              filled: true,
              fillColor: context.clr.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (v) {
              v.isNotEmpty
                  ? SocketService.instance.sendTypingStart(widget.consultationId)
                  : SocketService.instance.sendTypingStop(widget.consultationId);
            },
            onSubmitted: (_) => _sendMessage(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sendMessage,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: context.clr.accent, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

class _FullscreenImageScreen extends StatelessWidget {
  final String url;
  const _FullscreenImageScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator(color: Colors.white)),
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
          ),
        ),
      ),
    );
  }
}

class _AnimatedBubble extends StatefulWidget {
  final Widget child;
  const _AnimatedBubble({super.key, required this.child});

  @override
  State<_AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<_AnimatedBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}
