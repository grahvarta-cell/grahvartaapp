import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../l10n/app_strings.dart';
import '../../models/astrologer.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../theme/app_theme.dart';
import 'chat_history_screen.dart';

class ChatMessage {
  final String id;
  final String content;
  final String senderType;
  final DateTime timestamp;
  final String type;

  ChatMessage({required this.id, required this.content, required this.senderType, required this.timestamp, this.type = 'text'});
}

class ChatScreen extends StatefulWidget {
  final Astrologer astrologer;
  final String? consultationId;

  const ChatScreen({super.key, required this.astrologer, this.consultationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final SocketService _socket = SocketService.instance;
  late final ChatBloc _bloc;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _bloc = ChatBloc();
    _loadHistory();
    _initSocket();
  }

  String _sessionLabel(String? iso, String msgType) {
    try {
      final dt = DateTime.parse(iso!).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(dt.year, dt.month, dt.day);
      final months = ['', 'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final dateStr = msgDay == today
          ? 'Today'
          : msgDay == today.subtract(const Duration(days: 1))
              ? 'Yesterday'
              : '${dt.day} ${months[dt.month]} ${dt.year}';
      final timeStr = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      return msgType == 'session_start'
          ? '─── Session on $dateStr at $timeStr ───'
          : '─── Session ended · $dateStr at $timeStr ───';
    } catch (_) {
      return msgType == 'session_start' ? '─── Session started ───' : '─── Session ended ───';
    }
  }

  Future<void> _loadHistory() async {
    try {
      final data = await ApiService.getThreadMessages(widget.astrologer.id);
      final raw = List<dynamic>.from(data['messages'] ?? []);
      if (raw.isEmpty) return;
      final history = raw.map((m) {
        final msgType = m['message_type'] as String? ?? 'text';
        final isSession = msgType == 'session_start' || msgType == 'session_end';
        return ChatMessage(
          id: m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          content: isSession
              ? _sessionLabel(m['created_at']?.toString(), msgType)
              : (m['message'] as String? ?? m['content'] as String? ?? ''),
          senderType: isSession ? 'system' : (m['sender_type'] as String? ?? m['sender_role'] as String? ?? 'user'),
          timestamp: m['created_at'] != null ? DateTime.tryParse(m['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
        );
      }).toList();
      if (mounted) _bloc.add(ChatHistoryLoaded(history));
    } catch (_) {}
  }

  void _initSocket() {
    _socket.connect(
      onConnected: widget.consultationId == null ? _requestConsultation : null,
      onReconnect: () {
        // Re-request if we had an active consultation
        final state = _bloc.state;
        if (state.consultationId == null) {
          _requestConsultation();
        } else {
          // Rejoin existing consultation room
          _socket.emit('request_consultation', {
            'astrologer_id': widget.astrologer.id,
            'type': 'chat',
          });
        }
      },
    );

    _socket.on('consultation_queued', (data) {
      _bloc.add(ChatConsultationQueued(
        consultationId: data['consultation_id'] as String,
        position: data['position'] as int? ?? 1,
        estimatedWait: data['estimated_wait'] as int? ?? 5,
      ));
    });

    _socket.on('consultation_started', (data) {
      _bloc.add(ChatConsultationStarted());
      _bloc.add(ChatSystemMessage('Consultation started. You are being charged ₹${widget.astrologer.perMinuteRateChat.toInt()}/min'));
      // Fetch current wallet balance to display in billing bar
      ApiService.getWallet().then((wallet) {
        _bloc.add(ChatBillingCharged(wallet.balance));
      }).catchError((_) {});
    });

    _socket.on('new_message', (data) {
      if (data['sender_type'] != 'user') {
        _bloc.add(ChatMessageReceived(ChatMessage(
          id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          content: data['content'] ?? '',
          senderType: data['sender_type'],
          timestamp: DateTime.now(),
        )));
        _scrollToBottom();
      }
    });

    _socket.on('peer_typing', (data) {
      _bloc.add(ChatTypingChanged(data['is_typing'] ?? false));
    });

    _socket.on('billing_tick', (data) {
      _bloc.add(ChatBillingTick(
        seconds: data['seconds'] as int? ?? 0,
        amountCharged: (data['amount_charged'] as num?)?.toDouble() ?? 0,
      ));
    });

    _socket.on('billing_charged', (data) {
      _bloc.add(ChatBillingCharged(
        (data['balance_remaining'] as num?)?.toDouble() ?? 0,
      ));
    });

    _socket.on('consultation_ended', (data) {
      _bloc.add(ChatConsultationEnded(Map<String, dynamic>.from(data)));
      if (!_dialogShown) {
        _dialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showEndSummary(data);
        });
      }
    });

    _socket.on('consultation_rejected', (_) {
      _bloc.add(ChatSystemMessage('Astrologer is busy. Please try again later.'));
    });

    _socket.on('error', (data) {
      final msg = data['message'] ?? 'Something went wrong.';
      _bloc.add(ChatSystemMessage('⚠️ $msg'));
    });

    _socket.on('insufficient_balance', (data) {
      _bloc.add(ChatSystemMessage('⚠️ Insufficient balance. Required: ₹${data['required']}'));
    });
  }

  void _requestConsultation() {
    _socket.requestConsultation(widget.astrologer.id, 'chat');
    _bloc.add(ChatSystemMessage('Connecting to ${widget.astrologer.displayName}…'));
  }

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    final state = _bloc.state;
    if (text.isEmpty || state.consultationId == null) return;

    _bloc.add(ChatMessageSent(text));
    _socket.sendMessage(state.consultationId!, text);
    _socket.sendTypingStop(state.consultationId!);
    _messageCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showEndSummary(Map data) {
    final duration = data['duration'] ?? _bloc.state.timerSeconds;
    final total = data['total_amount'] ?? _bloc.state.totalCharged;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: context.clr.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Session Ended', style: TextStyle(color: context.clr.txtPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, color: context.clr.success, size: 48),
          const SizedBox(height: 12),
          Text('Duration: ${_formatTime(duration is int ? duration : (duration as num).toInt())}',
              style: TextStyle(color: context.clr.txtSecondary)),
          const SizedBox(height: 4),
          Text('Total: ₹${double.tryParse(total.toString())?.toStringAsFixed(2) ?? total}',
              style: TextStyle(color: context.clr.accent, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatHistoryScreen()));
            },
            child: Text('View Chats', style: TextStyle(color: context.clr.txtMuted)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _showRatingDialog(); },
            child: const Text('Rate Astrologer'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    double rating = 5;
    final reviewCtrl = TextEditingController();
    final consultationId = _bloc.state.consultationId;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: context.clr.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rate ${widget.astrologer.displayName}', style: TextStyle(color: context.clr.txtPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(
            onTap: () => setS(() => rating = i + 1.0),
            child: Icon(Icons.star, color: i < rating ? context.clr.accentAlt : context.clr.border, size: 36),
          ))),
          const SizedBox(height: 16),
          TextField(
            controller: reviewCtrl,
            maxLines: 3,
            style: TextStyle(color: context.clr.txtPrimary),
            decoration: InputDecoration(hintText: 'Write your review…', hintStyle: TextStyle(color: context.clr.txtMuted)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Skip', style: TextStyle(color: context.clr.txtMuted))),
          ElevatedButton(onPressed: () async {
            if (consultationId != null) {
              await ApiService.submitReview(widget.astrologer.id, rating.toInt(), reviewCtrl.text, consultationId);
            }
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) Navigator.pop(context);
          }, child: const Text('Submit')),
        ],
      )),
    );
  }

  void _endConsultation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.clr.card,
        title: Text(context.s.endSession, style: TextStyle(color: context.clr.txtPrimary)),
        content: Text(context.s.endSessionMsg, style: TextStyle(color: context.clr.txtSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.s.stayInSession, style: TextStyle(color: context.clr.txtMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final id = _bloc.state.consultationId;
              if (id != null) {
                _socket.endConsultation(id);
                if (!_socket.isConnected) {
                  await ApiService.endConsultation(id).catchError((_) {});
                }
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.clr.error),
            child: Text(context.s.endNow),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    final state = _bloc.state;
    if (state.consultationId != null && !state.isEnded) {
      _socket.endConsultation(state.consultationId!);
    }
    _socket.off('consultation_queued');
    _socket.off('consultation_started');
    _socket.off('new_message');
    _socket.off('peer_typing');
    _socket.off('billing_tick');
    _socket.off('billing_charged');
    _socket.off('consultation_ended');
    _socket.off('consultation_rejected');
    _socket.off('insufficient_balance');
    _socket.off('error');
    _socket.reset();
    _bloc.close();
    super.dispose();
  }

  static const _quickReplies = [
    '🙏 Namaste! I need your guidance',
    '💫 What does my future hold?',
    '❤️ Questions about my love life',
    '💼 Career & job guidance needed',
    '🏠 Family & relationship issues',
    '💰 Financial advice please',
    '🌙 My kundli reading please',
    '⭐ Lucky time for me today?',
  ];

  Future<bool> _onWillPop() async {
    final state = _bloc.state;
    if (state.isEnded) return true;
    if (state.consultationId == null && !state.isConnected) return true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.clr.card,
        title: Text(context.s.endSession, style: TextStyle(color: context.clr.txtPrimary)),
        content: Text(context.s.endSessionMsg, style: TextStyle(color: context.clr.txtSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.s.stayInSession, style: TextStyle(color: context.clr.txtMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: context.clr.error),
            child: Text(context.s.endNow),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _socket.endConsultation(state.consultationId!);
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: _buildAppBar(),
          body: Column(children: [
            // Billing bar — rebuilds only on timer/charge changes
            BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (prev, curr) =>
                  prev.isConnected != curr.isConnected ||
                  prev.timerSeconds != curr.timerSeconds ||
                  prev.totalCharged != curr.totalCharged ||
                  prev.walletBalance != curr.walletBalance,
              builder: (_, state) => state.isConnected ? _buildBillingBar(state) : const SizedBox.shrink(),
            ),
            // Messages — rebuilds only when messages list changes
            Expanded(child: Stack(children: [
              const Positioned.fill(child: CustomPaint(painter: _AstroBgPainter())),
              BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (prev, curr) => prev.messages != curr.messages,
                builder: (_, state) => _buildMessages(state),
              ),
            ])),
            // Typing indicator — rebuilds only on typing change
            BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (prev, curr) => prev.isPeerTyping != curr.isPeerTyping,
              builder: (_, state) => state.isPeerTyping ? _buildTypingIndicator() : const SizedBox.shrink(),
            ),
            // Quick replies — rebuilds only on connection/ended change
            BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (prev, curr) =>
                  prev.isConnected != curr.isConnected || prev.isEnded != curr.isEnded,
              builder: (_, state) =>
                  !state.isEnded && !state.isConnected ? _buildQuickReplies() : const SizedBox.shrink(),
            ),
            // Input bar — rebuilds only on connection/ended change
            BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (prev, curr) =>
                  prev.isConnected != curr.isConnected || prev.isEnded != curr.isEnded,
              builder: (_, state) => state.isEnded ? const SizedBox.shrink() : _buildInputBar(state),
            ),
          ]),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: context.clr.surface,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: context.clr.txtPrimary),
        onPressed: () async {
          final canPop = await _onWillPop();
          if (canPop && mounted) Navigator.pop(context);
        },
      ),
      title: BlocBuilder<ChatBloc, ChatState>(
        buildWhen: (prev, curr) =>
            prev.isConnected != curr.isConnected || prev.timerSeconds != curr.timerSeconds,
        builder: (_, state) => Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: context.clr.accent.withValues(alpha: 0.2),
            child: Text(widget.astrologer.displayName[0], style: TextStyle(color: context.clr.accent)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.astrologer.displayName,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.clr.txtPrimary)),
            Text(
              state.isConnected ? 'In session · ${_formatTime(state.timerSeconds)}' : 'Connecting…',
              style: TextStyle(fontSize: 11, color: context.clr.txtMuted),
            ),
          ])),
        ]),
      ),
      actions: [
        BlocBuilder<ChatBloc, ChatState>(
          buildWhen: (prev, curr) =>
              prev.isConnected != curr.isConnected || prev.isEnded != curr.isEnded || prev.consultationId != curr.consultationId,
          builder: (_, state) => !state.isEnded && (state.consultationId != null || state.isConnected)
              ? TextButton(
                  onPressed: _endConsultation,
                  child: Text(context.s.endConsultation, style: TextStyle(color: context.clr.error, fontWeight: FontWeight.w600)),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBillingBar(ChatState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: context.clr.accent.withValues(alpha: 0.1),
      child: Row(children: [
        Icon(Icons.timer, color: context.clr.accent, size: 16),
        const SizedBox(width: 6),
        Text(_formatTime(state.timerSeconds),
            style: TextStyle(color: context.clr.accent, fontWeight: FontWeight.bold, fontSize: 14)),
        const Spacer(),
        Text('₹${state.totalCharged.toStringAsFixed(2)} charged',
            style: TextStyle(color: context.clr.txtSecondary, fontSize: 12)),
        const SizedBox(width: 12),
        Icon(Icons.account_balance_wallet_outlined, color: context.clr.accentAlt, size: 14),
        const SizedBox(width: 4),
        Text('₹${state.walletBalance.toStringAsFixed(0)}',
            style: TextStyle(color: context.clr.accentAlt, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildMessages(ChatState state) {
    if (state.messages.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: context.clr.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.stars, color: context.clr.accent, size: 48),
        ),
        const SizedBox(height: 16),
        Text('Connecting to ${widget.astrologer.displayName}…',
            style: TextStyle(color: context.clr.txtSecondary, fontSize: 15)),
        const SizedBox(height: 8),
        const Text('Select a quick reply below to start',
            style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
      ]));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length,
      itemBuilder: (_, i) => _AnimatedBubble(
        key: ValueKey(state.messages[i].id),
        child: _buildMessageBubble(state.messages[i]),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.senderType == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(20)),
          child: Text(msg.content, style: TextStyle(color: context.clr.txtMuted, fontSize: 12), textAlign: TextAlign.center),
        )),
      );
    }

    final isUser = msg.senderType == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: context.clr.accent.withValues(alpha: 0.2),
              child: Text(widget.astrologer.displayName[0], style: TextStyle(color: context.clr.accent, fontSize: 11)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? context.clr.accent : context.clr.card,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(msg.content,
                  style: TextStyle(color: isUser ? Colors.white : context.clr.txtPrimary, fontSize: 14)),
              const SizedBox(height: 3),
              Text(DateFormat('h:mm a').format(msg.timestamp),
                  style: TextStyle(color: isUser ? Colors.white60 : context.clr.txtMuted, fontSize: 10)),
            ]),
          )),
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
          child: Text(widget.astrologer.displayName[0], style: TextStyle(color: context.clr.accent, fontSize: 10)),
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

  Widget _buildInputBar(ChatState state) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset > 0 ? bottomInset : 12),
      decoration: BoxDecoration(
        color: context.clr.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
      ),
      child: Row(children: [
        IconButton(icon: Icon(Icons.add_circle_outline, color: context.clr.txtMuted), onPressed: () {}),
        Expanded(child: TextField(
          controller: _messageCtrl,
          style: TextStyle(color: context.clr.txtPrimary, fontSize: 14),
          maxLines: 5, minLines: 1,
          onChanged: (v) {
            final id = state.consultationId;
            if (id != null && state.isConnected) {
              v.isNotEmpty ? _socket.sendTypingStart(id) : _socket.sendTypingStop(id);
            }
          },
          decoration: InputDecoration(
            hintText: context.s.typeMessage,
            hintStyle: TextStyle(color: context.clr.txtMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            filled: true, fillColor: context.clr.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        )),
        const SizedBox(width: 4),
        Material(
          color: state.consultationId != null ? context.clr.accent : context.clr.border,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: state.consultationId != null ? _sendMessage : null,
            child: SizedBox(
              width: 44, height: 44,
              child: Icon(Icons.send_rounded,
                  color: state.consultationId != null ? Colors.white : context.clr.txtMuted, size: 20),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () {
            _messageCtrl.text = _quickReplies[i];
            _sendMessage();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: context.clr.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.clr.accent.withValues(alpha: 0.4)),
            ),
            child: Text(_quickReplies[i],
                style: TextStyle(color: context.clr.accent, fontSize: 12, fontWeight: FontWeight.w500)),
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

class _AstroBgPainter extends CustomPainter {
  const _AstroBgPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = Random(42);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect,
        Paint()..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0D0D), Color(0xFF1A0A00), Color(0xFF0D0D0D)],
        ).createShader(rect));

    paint.color = Colors.white.withOpacity(0.06);
    for (int i = 0; i < 60; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 1.5 + 0.5,
        paint,
      );
    }

    for (final orb in [
      [size.width * 0.1, size.height * 0.15, 80.0, 0x0DE8762A],
      [size.width * 0.9, size.height * 0.4, 100.0, 0x08E8762A],
      [size.width * 0.3, size.height * 0.75, 70.0, 0x0AE8762A],
      [size.width * 0.8, size.height * 0.85, 90.0, 0x07FFD700],
    ]) {
      canvas.drawCircle(
        Offset(orb[0] as double, orb[1] as double),
        orb[2] as double,
        Paint()..shader = RadialGradient(colors: [Color(orb[3] as int), Colors.transparent])
            .createShader(Rect.fromCircle(center: Offset(orb[0] as double, orb[1] as double), radius: orb[2] as double)),
      );
    }

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    final points = List.generate(8, (_) => Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height));
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
