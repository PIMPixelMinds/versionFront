import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pim/core/constants/app_colors.dart';

void showChatbot(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ChatbotPopup(),
  );
}

class ChatbotPopup extends StatefulWidget {
  const ChatbotPopup({super.key});

  @override
  State<ChatbotPopup> createState() => _ChatbotPopupState();
}

class _ChatbotPopupState extends State<ChatbotPopup> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  final String geminiApiKey = "AIzaSyCujKp6IMWUmJx6qYTnSV9zK8aGTIl4_0g"; // Remplace par ta vraie clé

  Future<String> fetchAIResponse(String userMessage) async {
    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "You are a helpful assistant. Only answer questions about Multiple Sclerosis (MS) / Sclérose en plaques (SEP)."
                },
                {"text": userMessage}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      } else {
        return "API error: ${response.statusCode}";
      }
    } catch (e) {
      return "Erreur: $e";
    }
  }

  void _sendMessage() async {
    final localizations = AppLocalizations.of(context)!;
    final userMessage = _controller.text.trim();

    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({"user": userMessage});
    });

    final lower = userMessage.toLowerCase();
    final isMSRelated = lower.contains("sclérose en plaques") ||
        lower.contains("sep") ||
        lower.contains("multiple sclerosis") ||
        lower.contains("ms");

    if (isMSRelated) {
      final botResponse = await fetchAIResponse(userMessage);
      setState(() {
        _messages.add({"bot": botResponse});
      });
    } else {
      setState(() {
        _messages.add({"bot": localizations.onlyMsQuestions});
      });
    }

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color userColor = isDarkMode ? Colors.blue[300]! : Colors.blueAccent;
    final Color botColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.chatbotTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.primaryBlue,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color:
                            isDarkMode ? Colors.white : AppColors.primaryBlue),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Messages
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final role = _messages[index].keys.first;
                    final text = _messages[index][role]!;
                    final isUser = role == "user";

                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isUser ? userColor : botColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : (isDarkMode
                                    ? Colors.white70
                                    : Colors.black87),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: localizations.chatbotHint,
                        hintStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        filled: true,
                        fillColor:
                            isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send,
                        color: AppColors.primaryBlue, size: 28),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}