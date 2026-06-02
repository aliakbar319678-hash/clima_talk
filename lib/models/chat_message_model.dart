// ─── chat_message_model.dart ──────────────────────────────────────────────────
// This file defines the data structure for a single message in the AI chat.
// Every message bubble you see in the ChatScreen is built from one of these objects.
//
// Key Design Decisions:
//   - MessageRole enum: separates user messages from AI messages clearly
//   - isLoading flag: allows showing a "..." animation while AI is typing
//   - Factory constructors: make it easy to create messages of specific types
//   - copyWith: enables immutable updates (important for Riverpod state management)

// ChatMessageModel represents a single message in the AI chatbot conversation.
// Tracks sender role (user vs AI) and timestamp for display ordering.

// Enum defining who sent the message — either the human user or the AI assistant.
enum MessageRole { user, assistant }

class ChatMessageModel {
  final String id;              // Unique identifier (timestamp-based) for list keys
  final String content;         // The actual text content of the message
  final MessageRole role;       // Whether this is from the user or the AI
  final DateTime timestamp;     // When this message was created
  final bool isLoading;         // True while AI response is being generated

  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isLoading = false,
  });

  /// Creates a user-side message instance.
  /// The ID uses milliseconds since epoch to guarantee uniqueness.
  factory ChatMessageModel.user({required String content}) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
  }

  /// Creates an AI assistant message instance.
  /// isLoading can be set to true to show a typing placeholder ("...").
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
  /// The id 'loading' is fixed — there's always only one loading bubble at a time.
  factory ChatMessageModel.loading() {
    return ChatMessageModel(
      id: 'loading',
      content: '',             // No content — the UI shows "..." animation instead
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
  /// For example, when the AI finishes responding, we replace isLoading=true with
  /// isLoading=false and set the actual content.
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
