import 'package:bloc/bloc.dart';
import '../../screens/consultation/chat_screen.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(const ChatState()) {

    on<ChatConsultationQueued>((event, emit) {
      final msg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Connected! Position ${event.position} in queue. Est. wait: ${event.estimatedWait} min',
        senderType: 'system',
        timestamp: DateTime.now(),
      );
      emit(state.copyWith(
        consultationId: event.consultationId,
        messages: [...state.messages, msg],
      ));
    });

    on<ChatConsultationStarted>((event, emit) {
      emit(state.copyWith(isConnected: true));
    });

    on<ChatMessageReceived>((event, emit) {
      emit(state.copyWith(messages: [...state.messages, event.message]));
    });

    on<ChatMessageSent>((event, emit) {
      final msg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: event.text,
        senderType: 'user',
        timestamp: DateTime.now(),
      );
      emit(state.copyWith(messages: [...state.messages, msg]));
    });

    on<ChatTypingChanged>((event, emit) {
      emit(state.copyWith(isPeerTyping: event.isTyping));
    });

    on<ChatBillingTick>((event, emit) {
      emit(state.copyWith(
        timerSeconds: event.seconds,
        totalCharged: event.amountCharged,
      ));
    });

    on<ChatBillingCharged>((event, emit) {
      emit(state.copyWith(walletBalance: event.balanceRemaining));
    });

    on<ChatConsultationEnded>((event, emit) {
      final dur = event.data['duration'] ?? 0;
      final total = event.data['total_amount'] ?? 0;
      final reason = event.data['reason'];
      final text = reason == 'insufficient_balance'
          ? '⚠️ Session ended — insufficient wallet balance'
          : '✅ Consultation ended. Duration: ${_fmt(dur)}, Total: ₹$total';
      final msg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        senderType: 'system',
        timestamp: DateTime.now(),
      );
      emit(state.copyWith(
        isEnded: true,
        messages: [...state.messages, msg],
        timerSeconds: dur is int ? dur : int.tryParse(dur.toString()) ?? (dur as num?)?.toInt() ?? 0,
        totalCharged: total is double ? total : double.tryParse(total.toString()) ?? (total as num?)?.toDouble() ?? 0.0,
      ));
    });

    on<ChatSystemMessage>((event, emit) {
      final msg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: event.text,
        senderType: 'system',
        timestamp: DateTime.now(),
      );
      emit(state.copyWith(messages: [...state.messages, msg]));
    });

    on<ChatHistoryLoaded>((event, emit) {
      if (event.messages.isEmpty) return;
      final separator = ChatMessage(
        id: 'history_separator',
        content: '─── Previous conversations ───',
        senderType: 'system',
        timestamp: DateTime.now(),
      );
      emit(state.copyWith(messages: [...event.messages, separator, ...state.messages]));
    });
  }

  String _fmt(dynamic seconds) {
    final s = seconds is int ? seconds : int.tryParse(seconds.toString()) ?? (seconds as num?)?.toInt() ?? 0;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
