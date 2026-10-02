import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/local_storage_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class AIState {
  final List<ChatMessage> messages;
  final bool isThinking;

  AIState({
    required this.messages,
    this.isThinking = false,
  });

  AIState copyWith({
    List<ChatMessage>? messages,
    bool? isThinking,
  }) {
    return AIState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
    );
  }
}

class AINotifier extends StateNotifier<AIState> {
  AINotifier()
      : super(AIState(messages: [
          ChatMessage(
            text: "Hello! I'm your FinSight AI decision intelligence assistant. Ask me anything about your finances, budgets, or major purchase decisions!",
            isUser: false,
          )
        ])) {
    _loadStoredHistory();
  }

  Future<void> _loadStoredHistory() async {
    final history = await LocalStorageService.loadChatHistory();
    if (history != null && history.isNotEmpty) {
      state = state.copyWith(messages: history);
    }
  }

  void startNewSession() {
    final initialMsgs = [
      ChatMessage(
        text: "Hello! I'm your FinSight AI decision intelligence assistant. Ask me anything about your finances, budgets, or major purchase decisions!",
        isUser: false,
      )
    ];
    state = AIState(messages: initialMsgs, isThinking: false);
    LocalStorageService.saveChatHistory(initialMsgs);
  }

  void resetState() {
    startNewSession();
  }

  Future<void> sendMessage(String text, {int? year, int? month}) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(text: text, isUser: true);
    final updatedWithUser = [...state.messages, userMsg];
    state = state.copyWith(
      messages: updatedWithUser,
      isThinking: true,
    );
    LocalStorageService.saveChatHistory(updatedWithUser);

    final payload = <String, dynamic>{
      'prompt': text,
    };
    if (year != null) payload['year'] = year;
    if (month != null) payload['month'] = month;

    final res = await ApiClient.post('/ai/chat', payload);

    String replyText = "";
    if (res != null && res['reply'] != null) {
      replyText = res['reply'];
    } else {
      replyText = "⚠️ Unable to connect to FinSight AI backend. Please check your network connection and server status.";
    }

    final botMsg = ChatMessage(text: replyText, isUser: false);
    final finalMessages = [...state.messages, botMsg];
    state = state.copyWith(
      messages: finalMessages,
      isThinking: false,
    );
    LocalStorageService.saveChatHistory(finalMessages);
  }
}

final aiProvider = StateNotifierProvider<AINotifier, AIState>((ref) {
  return AINotifier();
});
