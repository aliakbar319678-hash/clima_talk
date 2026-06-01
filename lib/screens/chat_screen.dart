import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/chat_message_model.dart';
import '../providers/chat_provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/chat_bubble.dart';

const _kSuggestions = [
  'Will it rain today?',
  'What should I wear?',
  'Travel advice?',
  'Is it hot outside?',
];

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    _focusNode.unfocus();
    final weather = ref.read(weatherProvider).weather;
    ref.read(chatProvider.notifier).sendMessage(text, currentWeather: weather);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

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
    final chatAsync = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: subColor),
            onPressed: () => _showClearDialog(context),
            tooltip: 'Clear chat',
          ),
        ],
      ),
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
                onPressed: () => ref.invalidate(chatProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatContent(
    ChatState state,
    bool isDark,
    Color activeColor,
    Color inputBg,
    Color barBg,
  ) {
    return Column(
      children: [
        // Messages
        Expanded(
          child: state.messages.isEmpty
              ? _buildEmptyState(isDark, activeColor)
              : ListView.builder(
                  controller: _scrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: state.messages.length + (state.isTyping ? 1 : 0),
                  itemBuilder: (_, i) {
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

        // Suggestions
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

        // Input
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
            top: false,
            child: Row(
              children: [
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
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !state.isTyping,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: state.isTyping ? null : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: state.isTyping
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF1A6EEB), Color(0xFF5B4DFF)],
                            ),
                      color: state.isTyping ? Colors.grey : null,
                      shape: BoxShape.circle,
                    ),
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

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear the conversation history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
