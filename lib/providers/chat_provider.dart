import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message_model.dart';
import '../models/weather_model.dart';
import '../services/ai_service.dart';
import '../core/app_constants.dart';
import 'dart:developer' as dev;

/// ChatState holds the current conversation and UI-specific flags.
class ChatState {
  final List<ChatMessageModel> messages;
  final bool isTyping;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isTyping,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for managing AI Chat using AsyncNotifier for robust state handling.
class ChatNotifier extends AsyncNotifier<ChatState> {
  late final AIService _aiService;

  @override
  FutureOr<ChatState> build() async {
    _aiService = AIService();
    
    // Initial state with welcome message
    return ChatState(
      messages: [
        ChatMessageModel.assistant(
          content: 'Hi! I\'m your ClimaTalk AI companion. How can I help you today? 🌤️',
        ),
      ],
    );
  }

  /// Sends a message and updates state. Handles retries and error recovery.
  Future<void> sendMessage(String text, {WeatherModel? currentWeather}) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessageModel.user(content: text.trim());
    
    // Update local state immediately with user message and typing indicator
    final previousState = state.value ?? const ChatState();
    state = AsyncData(previousState.copyWith(
      messages: [...previousState.messages, userMsg],
      isTyping: true,
      clearError: true,
    ));

    await _fetchAIResponse(text, currentWeather);
  }

  /// Internal method to fetch AI response with retry logic
  Future<void> _fetchAIResponse(String text, WeatherModel? weather, {int retryCount = 0}) async {
    try {
      final history = state.value!.messages
          .where((m) => !m.isLoading && m.role != MessageRole.user || m.content != text)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      // Drop the very last user message from history as it's the current query
      if (history.isNotEmpty && history.last['role'] == 'user' && history.last['content'] == text) {
        history.removeLast();
      }

      final aiResponse = await _aiService.getWeatherGuidance(
        userQuery: text,
        history: history,
        currentWeather: weather,
      );

      final currentState = state.value!;
      final newAssistantMsg = ChatMessageModel.assistant(content: aiResponse);
      
      var updatedMessages = [...currentState.messages, newAssistantMsg];

      // Enforce history limit
      if (updatedMessages.length > AppConstants.maxChatHistory) {
        updatedMessages = updatedMessages.sublist(updatedMessages.length - AppConstants.maxChatHistory);
      }

      state = AsyncData(currentState.copyWith(
        messages: updatedMessages,
        isTyping: false,
      ));
    } catch (e, stack) {
      if (retryCount < AppConstants.maxRetries) {
        dev.log('Retrying AI request (${retryCount + 1}/${AppConstants.maxRetries}) due to: $e');
        await Future.delayed(const Duration(seconds: AppConstants.retryDelaySeconds));
        return _fetchAIResponse(text, weather, retryCount: retryCount + 1);
      }

      dev.log('AI Request failed after retries', error: e, stackTrace: stack);
      
      final currentState = state.value!;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      
      state = AsyncData(currentState.copyWith(
        isTyping: false,
        error: errorMsg,
        messages: [
          ...currentState.messages,
          ChatMessageModel.assistant(content: '⚠️ $errorMsg'),
        ],
      ));
    }
  }

  /// Clears the chat history
  void clearChat() {
    state = AsyncData(ChatState(
      messages: [
        ChatMessageModel.assistant(
          content: 'Chat cleared! Ask me anything about weather. 🌤️',
        ),
      ],
    ));
  }
}

final chatProvider = AsyncNotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);


