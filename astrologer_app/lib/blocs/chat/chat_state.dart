part of 'chat_bloc.dart';

class ChatState {
  final String? consultationId;
  final bool isConnected;
  final bool isEnded;
  final bool isPeerTyping;
  final int timerSeconds;
  final double totalCharged;
  final double walletBalance;
  final List<ChatMessage> messages;

  const ChatState({
    this.consultationId,
    this.isConnected = false,
    this.isEnded = false,
    this.isPeerTyping = false,
    this.timerSeconds = 0,
    this.totalCharged = 0,
    this.walletBalance = 0,
    this.messages = const [],
  });

  ChatState copyWith({
    String? consultationId,
    bool? isConnected,
    bool? isEnded,
    bool? isPeerTyping,
    int? timerSeconds,
    double? totalCharged,
    double? walletBalance,
    List<ChatMessage>? messages,
  }) {
    return ChatState(
      consultationId: consultationId ?? this.consultationId,
      isConnected: isConnected ?? this.isConnected,
      isEnded: isEnded ?? this.isEnded,
      isPeerTyping: isPeerTyping ?? this.isPeerTyping,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      totalCharged: totalCharged ?? this.totalCharged,
      walletBalance: walletBalance ?? this.walletBalance,
      messages: messages ?? this.messages,
    );
  }
}
