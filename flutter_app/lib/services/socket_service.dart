import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class SocketService {
  static SocketService? _instance;
  static SocketService get instance => _instance ??= SocketService._();
  SocketService._();

  IO.Socket? _socket;
  VoidCallback? _onReconnect;
  bool get isConnected => _socket?.connected ?? false;

  String _role = 'user';

  // Listeners registered before the socket object is created are buffered here
  // and flushed once _socket is initialized.
  final Map<String, List<Function(dynamic)>> _pendingListeners = {};

  Future<void> connect({VoidCallback? onConnected, VoidCallback? onReconnect, String role = 'user'}) async {
    _role = role;
    _onReconnect = onReconnect;
    final token = await ApiService.getToken();
    if (token == null) return;

    if (isConnected) {
      _socket!.emit('set_role', {'role': _role});
      onConnected?.call();
      return;
    }

    if (_socket != null) {
      _socket!.once('connect', (_) {
        _socket!.emit('set_role', {'role': _role});
        onConnected?.call();
      });
      _socket!.connect();
      return;
    }

    _socket = IO.io(
      ApiService.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(3000)
          .setReconnectionDelayMax(30000)
          .setAuth({'token': token})
          .setTimeout(30000)
          .build(),
    );

    // Flush any listeners that were registered before the socket was created
    _pendingListeners.forEach((event, handlers) {
      for (final h in handlers) {
        _socket!.on(event, h);
      }
    });
    _pendingListeners.clear();

    _socket!.onConnect((_) {
      debugPrint('Socket connected as $_role');
      _socket!.emit('set_role', {'role': _role});
      onConnected?.call();
    });

    _socket!.on('reconnect', (_) {
      debugPrint('Socket reconnected as $_role');
      _socket!.emit('set_role', {'role': _role});
      _onReconnect?.call();
    });

    _socket!.onDisconnect((reason) => debugPrint('Socket disconnected: $reason'));
    _socket!.onConnectError((e) => debugPrint('Socket connect error: $e'));
    _socket!.on('connect_timeout', (_) => debugPrint('Socket connect timeout'));

    _socket!.connect();
  }

  void disconnect() => _socket?.disconnect();

  void reset() {
    _socket?.dispose();
    _socket = null;
    _pendingListeners.clear();
  }

  void emit(String event, dynamic data) => _socket?.emit(event, data);

  /// Register an event listener. Safe to call before [connect] — the handler
  /// is buffered and applied as soon as the socket object is created.
  void on(String event, Function(dynamic) handler) {
    if (_socket != null) {
      _socket!.on(event, handler);
    } else {
      _pendingListeners.putIfAbsent(event, () => []).add(handler);
    }
  }

  void off(String event) {
    _socket?.off(event);
    _pendingListeners.remove(event);
  }

  // ── Consultation ──────────────────────────────────────────────
  void requestConsultation(String astrologerId, String type) {
    emit('request_consultation', {'astrologer_id': astrologerId, 'type': type});
  }

  void endConsultation(String consultationId) {
    emit('end_consultation', {'consultation_id': consultationId});
  }

  void sendMessage(String consultationId, String content, {String type = 'text'}) {
    emit('send_message', {'consultation_id': consultationId, 'content': content, 'message_type': type});
  }

  void sendTypingStart(String consultationId) => emit('typing_start', {'consultation_id': consultationId});
  void sendTypingStop(String consultationId) => emit('typing_stop', {'consultation_id': consultationId});

  // ── WebRTC ────────────────────────────────────────────────────
  void sendOffer(String consultationId, dynamic sdp) {
    emit('webrtc_offer', {'consultation_id': consultationId, 'sdp': sdp});
  }

  void sendAnswer(String consultationId, dynamic sdp) {
    emit('webrtc_answer', {'consultation_id': consultationId, 'sdp': sdp});
  }

  void sendIceCandidate(String consultationId, dynamic candidate) {
    emit('webrtc_ice_candidate', {'consultation_id': consultationId, 'candidate': candidate});
  }

  // ── Live ──────────────────────────────────────────────────────
  void joinLive(String sessionId) => emit('join_live', {'session_id': sessionId});
  void leaveLive(String sessionId) => emit('leave_live', {'session_id': sessionId});
  void sendLiveChat(String sessionId, String message) => emit('live_chat', {'session_id': sessionId, 'message': message});
  void sendTip(String sessionId, double amount, String message) => emit('send_tip', {'session_id': sessionId, 'amount': amount, 'message': message});

  void joinConsultation(String consultationId) => emit('join_consultation', {'consultation_id': consultationId});

  // ── Astrologer ────────────────────────────────────────────────
  void acceptConsultation(String consultationId) => emit('accept_consultation', {'consultation_id': consultationId});
  void rejectConsultation(String consultationId) => emit('reject_consultation', {'consultation_id': consultationId});
  void astrologerEndConsultation(String consultationId) => emit('end_consultation', {'consultation_id': consultationId});
}
