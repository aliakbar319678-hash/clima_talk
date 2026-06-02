// ─── chat_provider.dart ───────────────────────────────────────────────────────
// This provider manages ALL state related to the AI chat conversation.
// It follows the Riverpod AsyncNotifier pattern, which is ideal for async
// operations like network calls.
//
// Architecture:
//   ChatState      → The data object (immutable snapshot of conversation state)
//   ChatNotifier   → The logic class that modifies the state
//   chatProvider   → The Riverpod provider that exposes the notifier to the UI
//
// Flow: User types message → ChatScreen calls sendMessage() → ChatNotifier
//       appends user message → fetches AI response → appends AI response → UI rebuilds.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message_model.dart';
import '../models/weather_model.dart';
import '../services/ai_service.dart';
import '../core/app_constants.dart';
import 'dart:developer' as dev;

// ─── ChatState ────────────────────────────────────────────────────────────────
// An immutable data class that represents a single "snapshot" of the chat.
// Using immutable state means every change creates a NEW state object,
// which is the foundation of reactive programming in Riverpod.
/// ChatState holds the current conversation and UI-specific flags.
class ChatState {
  final List<ChatMessageModel> messages; // All messages in the conversation
  final bool isTyping;                   // True while waiting for AI to respond
  final String? error;                   // Non-null when an error has occurred

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.error,
  });

  // copyWith is a Dart pattern for creating modified copies of immutable objects.
  // Instead of mutating state directly, we create a new ChatState with updated fields.
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

// ─── ChatNotifier ─────────────────────────────────────────────────────────────
// AsyncNotifier manages state that involves asynchronous initialization.
// build() runs once when the provider is first accessed.
/// Notifier for managing AI Chat using AsyncNotifier for robust state handling.
class ChatNotifier extends AsyncNotifier<ChatState> {
  late final AIService _aiService;

  @override
  FutureOr<ChatState> build() async {
    // Initialize the AI service once when the provider is created.
    _aiService = AIService();
    
    // Set the initial state with a welcome message from the AI assistant.
    // This gives users a friendly starting point for the conversation.
    return ChatState(
      messages: [
        ChatMessageModel.assistant(
          content: 'Hi! I\'m your ClimaTalk AI companion. How can I help you today? 🌤️',
        ),
      ],
    );
  }

  /// Sends a message and updates state. Handles retries and error recovery.
  /// This is the main entry point called by the ChatScreen UI.
  Future<void> sendMessage(String text, {WeatherModel? currentWeather}) async {
    // Ignore empty messages — no need to send a blank query to the AI.
    if (text.trim().isEmpty) return;

    // Create the user's message object immediately.
    final userMsg = ChatMessageModel.user(content: text.trim());
    
    // Immediately append the user's message to the UI and show "isTyping" indicator.
    // This gives instant feedback — the user sees their message appear right away.
    final previousState = state.value ?? const ChatState();
    state = AsyncData(previousState.copyWith(
      messages: [...previousState.messages, userMsg],
      isTyping: true,      // Show the "..." typing animation for the AI
      clearError: true,    // Clear any previous error when starting a new message
    ));

    // Now fetch the AI's response asynchronously in the background.
    await _fetchAIResponse(text, currentWeather);
  }

  /// Internal method to fetch AI response with retry logic.
  /// If the request fails, it retries up to maxRetries times with a delay between each.
  Future<void> _fetchAIResponse(String text, WeatherModel? weather, {int retryCount = 0}) async {
    try {
      // Build the conversation history to send to the AI for context.
      // We exclude loading placeholders and convert to the API's expected format.
      final history = state.value!.messages
          .where((m) => !m.isLoading && m.role != MessageRole.user || m.content != text)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      // Drop the very last user message from history as it's the current query
      // (it will be added separately in the AI service).
      if (history.isNotEmpty && history.last['role'] == 'user' && history.last['content'] == text) {
        history.removeLast();
      }

      // Call the AI service and await the text response.
      final aiResponse = await _aiService.getWeatherGuidance(
        userQuery: text,
        history: history,
        currentWeather: weather,
      );

      // Create the AI's reply message object and append it to the conversation.
      final currentState = state.value!;
      final newAssistantMsg = ChatMessageModel.assistant(content: aiResponse);
      
      var updatedMessages = [...currentState.messages, newAssistantMsg];

      // Enforce history limit — prevent memory issues from extremely long conversations.
      // If the list exceeds maxChatHistory, remove the oldest messages from the start.
      if (updatedMessages.length > AppConstants.maxChatHistory) {
        updatedMessages = updatedMessages.sublist(updatedMessages.length - AppConstants.maxChatHistory);
      }

      // Update the state: add AI's reply, hide the typing indicator.
      state = AsyncData(currentState.copyWith(
        messages: updatedMessages,
        isTyping: false,
      ));
    } catch (e, stack) {
      // If the request failed and we still have retry attempts left, wait and retry.
      if (retryCount < AppConstants.maxRetries) {
        dev.log('Retrying AI request (${retryCount + 1}/${AppConstants.maxRetries}) due to: $e');
        await Future.delayed(const Duration(seconds: AppConstants.retryDelaySeconds));
        return _fetchAIResponse(text, weather, retryCount: retryCount + 1);
      }

      // All retries exhausted — display the error as a chat message from the AI.
      dev.log('AI Request failed after retries', error: e, stackTrace: stack);
      
      final currentState = state.value!;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      
      // Show the error as an AI message in the chat with a ⚠️ prefix.
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

  /// Clears the chat history and resets the conversation with a fresh welcome message.
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

// ─── Provider Declaration ─────────────────────────────────────────────────────
// This is how the UI accesses the chat state. Any widget that calls
// ref.watch(chatProvider) will rebuild whenever ChatState changes.
final chatProvider = AsyncNotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);


