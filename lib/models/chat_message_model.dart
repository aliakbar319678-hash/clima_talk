// ChatMessageModel represents a single message in the AI chatbot conversation.
// Tracks sender role (user vs AI) and timestamp for display ordering.

enum MessageRole { user, assistant }

class ChatMessageModel {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isLoading; // True while AI response is being generated

  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isLoading = false,
  });

  /// Creates a user-side message instance.
  factory ChatMessageModel.user({required String content}) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
  }

  /// Creates an AI assistant message instance.
  factory ChatMessageModel.assistant({
    required String content,
    bool isLoading = false,
  }) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isLoading: isLoading,
    );
  }

  /// Creates a loading placeholder while waiting for AI response.
  factory ChatMessageModel.loading() {
    return ChatMessageModel(
      id: 'loading',
      content: '',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }

  /// Returns true if this message is from the AI assistant.
  bool get isAssistant => role == MessageRole.assistant;

  /// Returns true if this message is from the user.
  bool get isUser => role == MessageRole.user;

  /// Creates a copy of this model with optional overrides (useful for state updates).
  ChatMessageModel copyWith({String? content, bool? isLoading}) {
    return ChatMessageModel(
      id: id,
      content: content ?? this.content,
      role: role,
      timestamp: timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
