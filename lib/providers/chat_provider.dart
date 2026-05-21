// ChatProvider manages the AI chatbot conversation state.
// Corresponds to the AIChatbot class from SRS Section 3.4.3.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message_model.dart';
import '../models/weather_model.dart';
import '../services/ai_service.dart';
import '../services/session_cache_service.dart';
import '../core/app_constants.dart';

/// Holds the list of chat messages and loading state.
class ChatState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null;

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for AI chatbot conversation management.
class ChatNotifier extends Notifier<ChatState> {
  late final AIService _aiService;
  late final SessionCacheService _cache;

  @override
  ChatState build() {
    _aiService = AIService();
    _cache = SessionCacheService();

    // Add a welcome message when the chat screen first loads
    return ChatState(
      messages: [
        ChatMessageModel.assistant(
          content:
              'Hi! I\'m your ClimaTalk AI weather assistant. '
              'Ask me anything about weather — "Will it rain today?", '
              '"What should I wear?", or "Is it safe to travel?" 🌤️',
        ),
      ],
    );
  }

  /// Sends a user message and requests an AI response.
  Future<void> sendMessage(
    String userText, {
    WeatherModel? currentWeather,
  }) async {
    if (userText.trim().isEmpty) return;

    // Add user's message to the conversation
    final userMessage = ChatMessageModel.user(content: userText.trim());
    final loadingMessage = ChatMessageModel.loading();

    state = state.copyWith(
      messages: [...state.messages, userMessage, loadingMessage],
      isLoading: true,
      errorMessage: null,
    );

    try {
      // Check session cache for repeated queries (performance optimization)
      final cacheKey = SessionCacheService.aiKey(userText);
      String? cachedResponse = _cache.retrieve<String>(cacheKey);

      final aiResponse =
          cachedResponse ??
          await _aiService.getWeatherGuidance(
            userQuery: userText.trim(),
            currentWeather: currentWeather,
          );

      // Cache the AI response for repeated similar queries
      if (cachedResponse == null) {
        _cache.store(cacheKey, aiResponse);
      }

      // Replace loading message with actual AI response
      final updatedMessages = List<ChatMessageModel>.from(
        state.messages.where((m) => !m.isLoading),
      )..add(ChatMessageModel.assistant(content: aiResponse));

      // Enforce max chat history limit from SRS
      final trimmed = updatedMessages.length > AppConstants.maxChatHistory
          ? updatedMessages.sublist(
              updatedMessages.length - AppConstants.maxChatHistory,
            )
          : updatedMessages;

      state = state.copyWith(messages: trimmed, isLoading: false);
    } catch (e) {
      // Remove the loading indicator and show error in the chat
      final messagesWithoutLoading = state.messages
          .where((m) => !m.isLoading)
          .toList();

      final errorMessage = e.toString().replaceAll('Exception: ', '');
      
      state = state.copyWith(
        messages: [
          ...messagesWithoutLoading,
          ChatMessageModel.assistant(
            content: 'Error: $errorMessage ⚠️',
          ),
        ],
        isLoading: false,
        errorMessage: errorMessage,
      );
    }
  }

  /// Clears the conversation history and resets to welcome message.
  void clearChat() {
    state = ChatState(
      messages: [
        ChatMessageModel.assistant(
          content: 'Chat cleared! Ask me anything about weather. 🌤️',
        ),
      ],
    );
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
