enum MessageType {
  user,
  assistant,
  system,
}

class ChatMessage {
  final String text;
  final MessageType messageType;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.messageType,
    required this.timestamp,
  });

  // For backward compatibility
  bool get isUser => messageType == MessageType.user;
  bool get isSystem => messageType == MessageType.system;
  bool get isAssistant => messageType == MessageType.assistant;
}