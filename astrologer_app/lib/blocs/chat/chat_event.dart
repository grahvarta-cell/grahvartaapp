part of 'chat_bloc.dart';

abstract class ChatEvent {}

class ChatConsultationQueued extends ChatEvent {
  final String consultationId;
  final int position;
  final int estimatedWait;
  ChatConsultationQueued({required this.consultationId, required this.position, required this.estimatedWait});
}

class ChatConsultationStarted extends ChatEvent {}

class ChatMessageReceived extends ChatEvent {
  final ChatMessage message;
  ChatMessageReceived(this.message);
}

class ChatMessageSent extends ChatEvent {
  final String text;
  ChatMessageSent(this.text);
}

class ChatTypingChanged extends ChatEvent {
  final bool isTyping;
  ChatTypingChanged(this.isTyping);
}

class ChatBillingTick extends ChatEvent {
  final int seconds;
  final double amountCharged;
  ChatBillingTick({required this.seconds, required this.amountCharged});
}

class ChatBillingCharged extends ChatEvent {
  final double balanceRemaining;
  ChatBillingCharged(this.balanceRemaining);
}

class ChatConsultationEnded extends ChatEvent {
  final Map<String, dynamic> data;
  ChatConsultationEnded(this.data);
}

class ChatSystemMessage extends ChatEvent {
  final String text;
  ChatSystemMessage(this.text);
}

class ChatHistoryLoaded extends ChatEvent {
  final List<ChatMessage> messages;
  ChatHistoryLoaded(this.messages);
}
