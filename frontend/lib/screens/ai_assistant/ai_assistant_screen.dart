import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/ai_provider.dart';
import '../../providers/finance_provider.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickPrompts = [
    "Where did I overspend?",
    "How much should I save next month?",
    "Can I afford a major purchase?",
    "Suggest ways to reduce expenses."
  ];

  void _send(String prompt) {
    if (prompt.trim().isEmpty) return;
    _textController.clear();
    final finState = ref.read(financeProvider);
    ref.read(aiProvider.notifier).sendMessage(
          prompt,
          year: finState.selectedYear,
          month: finState.selectedMonth,
        );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text("AI Financial Advisor", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Start New Session",
            icon: const Icon(Icons.add_comment_rounded, color: AppColors.primary),
            onPressed: () {
              ref.read(aiProvider.notifier).startNewSession();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Started a fresh AI conversation session."),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Prompts Chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickPrompts.length,
              itemBuilder: (context, index) {
                final chipText = _quickPrompts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(chipText, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () => _send(chipText),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: aiState.messages.length,
              itemBuilder: (context, index) {
                final msg = aiState.messages[index];
                return _buildChatBubble(msg.text, msg.isUser, isDark);
              },
            ),
          ),

          if (aiState.isThinking)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text("FinSight AI is analyzing your financial context...", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: _send,
                    decoration: InputDecoration(
                      hintText: "Ask about your budget, loans, or savings...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: () => _send(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser, bool isDark) {
    final maxBubbleWidth = (MediaQuery.of(context).size.width * 0.82).clamp(280.0, 680.0);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          border: isUser
              ? null
              : Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isUser
            ? Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              )
            : FormattedMarkdownText(text: text, isDark: isDark),
      ),
    );
  }
}

class FormattedMarkdownText extends StatelessWidget {
  final String text;
  final bool isDark;

  const FormattedMarkdownText({super.key, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accentColor = isDark ? const Color(0xFF38BDF8) : AppColors.primary;

    final lines = text.split('\n');
    List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trimRight();

      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      if (line.startsWith('### ') || line.startsWith('## ') || line.startsWith('# ')) {
        final headingText = line.replaceAll(RegExp(r'^#+\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Text(
              headingText,
              style: GoogleFonts.outfit(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: accentColor,
              ),
            ),
          ),
        );
      } else if (line.trim().startsWith('• ') || line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        final bulletText = line.trim().substring(2);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 2.0, bottom: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• ", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor)),
                Expanded(
                  child: RichText(
                    text: _parseFormattedSpan(bulletText, textColor, accentColor),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: RichText(
              text: _parseFormattedSpan(line, textColor, accentColor),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  TextSpan _parseFormattedSpan(String input, Color textColor, Color accentColor) {
    List<InlineSpan> spans = [];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(input)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: input.substring(lastMatchEnd, match.start),
          style: GoogleFonts.inter(fontSize: 14.5, height: 1.5, color: textColor),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: GoogleFonts.inter(fontSize: 14.5, height: 1.5, fontWeight: FontWeight.bold, color: textColor),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < input.length) {
      spans.add(TextSpan(
        text: input.substring(lastMatchEnd),
        style: GoogleFonts.inter(fontSize: 14.5, height: 1.5, color: textColor),
      ));
    }

    return TextSpan(children: spans);
  }
}

