import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

// --------------- State ---------------

class ChatState {
  final bool loading;
  final bool isEnded;
  final bool isPeerTyping;
  final int elapsed;
  final List<Map<String, dynamic>> messages;

  const ChatState({
    this.loading = true,
    this.isEnded = false,
    this.isPeerTyping = false,
    this.elapsed = 0,
    this.messages = const [],
  });

  ChatState copyWith({
    bool? loading,
    bool? isEnded,
    bool? isPeerTyping,
    int? elapsed,
    List<Map<String, dynamic>>? messages,
  }) =>
      ChatState(
        loading: loading ?? this.loading,
        isEnded: isEnded ?? this.isEnded,
        isPeerTyping: isPeerTyping ?? this.isPeerTyping,
        elapsed: elapsed ?? this.elapsed,
        messages: messages ?? this.messages,
      );
}

// --------------- Cubit ---------------

class ChatCubit extends Cubit<ChatState> {
  final String consultationId;
  final String? userId;

  ChatCubit({required this.consultationId, this.userId}) : super(const ChatState());

  Future<void> loadHistory() async {
    final msgs = <Map<String, dynamic>>[];

    if (userId != null && userId!.isNotEmpty) {
      try {
        final data = await ApiService.getAstrologerUserMessages(userId!);
        final old = List<dynamic>.from(data['messages'] ?? []);
        if (old.isNotEmpty) {
          msgs.addAll(old.map((m) {
            final map = Map<String, dynamic>.from(m as Map);
            map['type'] = map['message_type'] ?? map['type'] ?? 'text';
            return map;
          }));
          msgs.add({'sender_type': 'system', 'content': '─── Current session ───', 'created_at': DateTime.now().toIso8601String()});
        }
      } catch (_) {}
    }

    try {
      final current = await ApiService.getAstrologerConsultationMessages(consultationId);
      msgs.addAll(current.map((m) {
        final map = Map<String, dynamic>.from(m as Map);
        map['type'] = map['message_type'] ?? map['type'] ?? 'text';
        return map;
      }));
      emit(state.copyWith(loading: false, messages: List.from(msgs)));
    } catch (_) {
      emit(state.copyWith(loading: false, messages: List.from(msgs)));
    }
  }

  void addMessage(Map<String, dynamic> msg) {
    emit(state.copyWith(messages: [...state.messages, msg]));
  }

  void updateBillingTick(int seconds) {
    emit(state.copyWith(elapsed: seconds));
  }

  void setPeerTyping(bool typing) {
    emit(state.copyWith(isPeerTyping: typing));
  }

  void setEnded() {
    emit(state.copyWith(isEnded: true));
  }

  void sendTextMessage(String text) {
    if (text.isEmpty || state.isEnded) return;
    SocketService.instance.sendTypingStop(consultationId);
    SocketService.instance.sendMessage(consultationId, text);
    addMessage({
      'sender_type': 'astrologer',
      'content': text,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> uploadAndSendImage(File imageFile) async {
    final localId = 'uploading_${DateTime.now().millisecondsSinceEpoch}';
    addMessage({
      'id': localId,
      'sender_type': 'astrologer',
      'content': '',
      'type': 'image_uploading',
      'created_at': DateTime.now().toIso8601String(),
    });

    try {
      final url = await ApiService.uploadChatImage(imageFile);
      final updated = List<Map<String, dynamic>>.from(state.messages);
      final idx = updated.indexWhere((m) => m['id'] == localId);
      if (idx != -1) {
        updated[idx] = {
          'id': localId,
          'sender_type': 'astrologer',
          'content': url,
          'type': 'image',
          'created_at': DateTime.now().toIso8601String(),
        };
      }
      emit(state.copyWith(messages: updated));
      SocketService.instance.sendMessage(consultationId, url, type: 'image');
    } catch (_) {
      final updated = List<Map<String, dynamic>>.from(state.messages);
      final idx = updated.indexWhere((m) => m['id'] == localId);
      if (idx != -1) {
        updated[idx] = {
          'sender_type': 'astrologer',
          'content': '⚠️ Image failed to send',
          'type': 'text',
          'created_at': DateTime.now().toIso8601String(),
        };
      }
      emit(state.copyWith(messages: updated));
    }
  }
}
