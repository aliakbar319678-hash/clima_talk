// ─── chat_screen.dart ─────────────────────────────────────────────────────────
// This is the AI Chat screen — the most important feature of ClimaTalk.
// It provides a WhatsApp-style chat UI where the user can converse with an
// AI weather assistant powered by the Pollinations AI text API.
//
// Screen Layout:
//   ┌─────────────────────────────┐
//   │ AppBar: "AI Weather Chat"   │
//   ├─────────────────────────────┤
//   │ Chat messages list          │  (scrollable, newest at bottom)
//   ├─────────────────────────────┤
//   │ Quick suggestion chips      │  (tap to auto-fill input)
//   ├─────────────────────────────┤
//   │ Text input + Send button    │
//   └─────────────────────────────┘

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/chat_message_model.dart';
import '../providers/chat_provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/chat_bubble.dart';

// Predefined suggestion chips shown above the input field.
// These let users quickly ask common weather questions with one tap.
const _kSuggestions = [
  'Will it rain today?',
  'What should I wear?',
  'Travel advice?',
  'Is it hot outside?',
];

// ─── ChatScreen ───────────────────────────────────────────────────────────────
// ConsumerStatefulWidget: needs both State (for controllers) and Riverpod (for providers).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  // TextEditingController: manages the text in the input field.
  final TextEditingController _inputCtrl = TextEditingController();
  // ScrollController: lets us programmatically scroll to the bottom of the chat.
  final ScrollController _scrollCtrl = ScrollController();
  // FocusNode: lets us programmatically unfocus the keyboard (close it after sending).
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    // Always dispose controllers and nodes to prevent memory leaks.
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Send Message ──────────────────────────────────────────────────────────
  // Called when the user taps the Send button or presses Enter on the keyboard.
  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return; // Do nothing for blank messages
    _inputCtrl.clear();        // Clear the input field immediately
    _focusNode.unfocus();      // Dismiss the keyboard

    // Read the current weather from weatherProvider to pass as AI context.
    final weather = ref.read(weatherProvider).weather;
    // Tell the ChatNotifier to send the message (this triggers the AI API call).
    ref.read(chatProvider.notifier).sendMessage(text, currentWeather: weather);

    // Scroll to the bottom AFTER the new message widget has been built.
    // addPostFrameCallback ensures we scroll after the build is complete.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // Smoothly scrolls the list view to the very bottom (latest message).
  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch chatProvider — this widget rebuilds whenever chat state changes.
    final chatAsync = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-responsive colors — the UI adapts to both dark and light modes.
    final titleColor = isDark ? Colors.white : AppTheme.textPrimaryDark;
    final subColor = isDark ? AppTheme.textSecondaryLight : AppTheme.textSecondaryDark;
    final activeColor = isDark ? AppTheme.neonBlue : AppTheme.primaryBlue;
    final inputBg = isDark ? AppTheme.nightCardAlt : const Color(0xFFF2F5FF);
    final barBg = isDark
        ? const Color(0xFF0A1545).withValues(alpha: 0.95)
        : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI bot icon in a gradient container
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B4DFF), Color(0xFFAB47BC)],
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'AI Weather Chat',
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          // Clear chat button — shows a confirmation dialog before clearing.
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: subColor),
            onPressed: () => _showClearDialog(context),
            tooltip: 'Clear chat',
          ),
        ],
      ),
      // ─── Body: Three States (loading / error / data) ─────────────────────
      // chatAsync.when() handles all three states of AsyncNotifier automatically.
      body: chatAsync.when(
        data: (state) => _buildChatContent(state, isDark, activeColor, inputBg, barBg),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load chat: $err'),
              ElevatedButton(
                // ref.invalidate() re-creates the provider from scratch (fresh start).
                onPressed: () => ref.invalidate(chatProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Chat Content Builder ──────────────────────────────────────────────────
  // Builds the full chat layout: messages + suggestions + input bar.
  Widget _buildChatContent(
    ChatState state,
    bool isDark,
    Color activeColor,
    Color inputBg,
    Color barBg,
  ) {
    return Column(
      children: [
        // ─── Messages List ──────────────────────────────────────────────────
        // Expanded fills all remaining space between AppBar and input bar.
        Expanded(
          child: state.messages.isEmpty
              ? _buildEmptyState(isDark, activeColor)
              : ListView.builder(
                  controller: _scrollCtrl,
                  physics: const BouncingScrollPhysics(), // Rubber-band scroll effect
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  // +1 item count to add the "AI is typing..." bubble when needed.
                  itemCount: state.messages.length + (state.isTyping ? 1 : 0),
                  itemBuilder: (_, i) {
                    // If we're on the extra item, show the typing indicator bubble.
                    if (i == state.messages.length) {
                      return ChatBubble(message: ChatMessageModel.assistant(
                        content: '...',
                        isLoading: true,
                      ));
                    }
                    return ChatBubble(message: state.messages[i]);
                  },
                ),
        ),

        // ─── Quick Suggestion Chips ─────────────────────────────────────────
        // Horizontally scrollable row of preset questions for easy interaction.
        // Only shown when AI is NOT typing (to avoid input-during-processing).
        if (!state.isTyping)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: _kSuggestions
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        // Tapping a suggestion auto-fills AND immediately sends the message.
                        onPressed: () {
                          _inputCtrl.text = s;
                          _sendMessage();
                        },
                        backgroundColor: activeColor.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: activeColor.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                        labelStyle: TextStyle(
                          color: activeColor,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        // ─── Message Input Bar ──────────────────────────────────────────────
        // Contains the text field and the animated send button.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: barBg,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppTheme.nightBorder.withValues(alpha: 0.4)
                    : const Color(0xFFE0E8F5),
                width: 0.8,
              ),
            ),
          ),
          child: SafeArea(
            top: false, // Don't add extra padding at the top
            child: Row(
              children: [
                // ─── Text Input Field ──────────────────────────────────────
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.nightBorder.withValues(alpha: 0.4)
                            : const Color(0xFFCDD5E8),
                        width: 0.8,
                      ),
                    ),
                    child: TextField(
                      controller: _inputCtrl,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask about the weather...',
                        hintStyle: TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 14,
                        ),
                        border: InputBorder.none, // No underline border
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(), // Send on keyboard "done"
                      enabled: !state.isTyping, // Disable input while AI is responding
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // ─── Send Button ───────────────────────────────────────────
                // AnimatedContainer smoothly transitions between active (gradient)
                // and disabled (grey) states while the AI is typing.
                GestureDetector(
                  onTap: state.isTyping ? null : _sendMessage, // Disable tap during AI response
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: state.isTyping
                          ? null  // No gradient when disabled
                          : const LinearGradient(
                              colors: [Color(0xFF1A6EEB), Color(0xFF5B4DFF)],
                            ),
                      color: state.isTyping ? Colors.grey : null, // Grey when disabled
                      shape: BoxShape.circle,
                    ),
                    // Show spinner while AI is responding, send icon otherwise.
                    child: state.isTyping
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────
  // Shown when there are no messages yet (chat was just cleared, etc.)
  Widget _buildEmptyState(bool isDark, Color activeColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B4DFF), Color(0xFFAB47BC)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'AI Weather Assistant',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about the weather!',
            style: TextStyle(
              color: isDark
                  ? AppTheme.textSecondaryLight
                  : AppTheme.textSecondaryDark,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Clear Chat Confirmation Dialog ────────────────────────────────────────
  // Shows a modal dialog asking the user to confirm before wiping the chat history.
  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear the conversation history?',
        ),
        actions: [
          // "Cancel" dismisses the dialog without doing anything.
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          // "Clear" dismisses the dialog AND calls clearChat() on the notifier.
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(chatProvider.notifier).clearChat();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
