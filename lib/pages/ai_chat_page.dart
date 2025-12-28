import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;

  static  String? geminiApiKey = dotenv.env['GEMINI_API_KEY'];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------- NORMALIZE TEXT ----------------

  String normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  // ---------------- SEMANTIC INTENT EXPANSION ----------------

  List<String> expandQuery(String q) {
    q = normalize(q);

    final synonyms = {
      "exam": [
        "exam",
        "exams",
        "exam date",
        "exam dates",
        "exam schedule",
        "exam timetable",
        "examination",
        "exam starting",
        "exam time"
      ],
      "form": [
        "form",
        "forms",
        "any form",
        "form out",
        "oe form",
        "application form",
        "submission form"
      ],
      "deadline": [
        "deadline",
        "last date",
        "due date",
        "closing date",
        "submission"
      ],
      "notice": [
        "notice",
        "important notice",
        "announcement",
        "circular",
        "update"
      ],
      "event": [
        "event",
        "fest",
        "hackathon",
        "workshop",
        "seminar",
        "competition"
      ],
    };

    List<String> out = [q];

    for (final entry in synonyms.entries) {
      if (q.contains(entry.key)) out.addAll(entry.value);
    }

    return out.map(normalize).toList();
  }

  // ---------------- SMART FIRESTORE SEARCH ----------------

  Future<List<Map<String, dynamic>>> _queryCampusItems(String query) async {
    final now = DateTime.now();

    // expanded intent phrases
    final expanded = expandQuery(query);

    // token keywords: "any form" → ["any","form"]
    final keywords = normalize(query)
        .split(" ")
        .where((w) => w.trim().isNotEmpty)
        .toList();

    final snap = await FirebaseFirestore.instance
        .collection("campus_items")
        .where("active", isEqualTo: true)
        .get();

    final results = snap.docs.where((doc) {
      final d = doc.data();

      final type = normalize(d["type"] ?? "");
      final title = normalize(d["title"] ?? "");
      final desc = normalize(d["description"] ?? "");

      final tagsList = (d["tags"] ?? []) as List;
      final tags =
          tagsList.map((e) => normalize(e.toString())).toList();

      final combined = "$type $title $desc ${tags.join(" ")}";

      final start = (d["startDate"] as Timestamp?)?.toDate();
      final end = (d["endDate"] as Timestamp?)?.toDate();

      final isEventType = type.contains("event") ||
          type.contains("hackathon") ||
          type.contains("workshop") ||
          type.contains("seminar");

      // ✔ Only events are time-bound
      if (isEventType) {
        if (start != null && now.isBefore(start)) return false;
        if (end != null && now.isAfter(end)) return false;
      }

      // 1️⃣ semantic phrase matching
      final semanticMatch = expanded.any((q) => combined.contains(q));

      // 2️⃣ keyword token matching
      final keywordMatch =
          keywords.any((k) => k.length > 2 && combined.contains(k));

      // 3️⃣ direct tag match
      final tagMatch = keywords.any((k) => tags.contains(k));

      return semanticMatch || keywordMatch || tagMatch;
    }).map((d) => Map<String, dynamic>.from(d.data())).toList();

    // sort – nearest upcoming first when date exists
    results.sort((a, b) {
      final d1 = (a["startDate"] as Timestamp?)?.toDate() ?? DateTime(1970);
      final d2 = (b["startDate"] as Timestamp?)?.toDate() ?? DateTime(1970);
      return d1.compareTo(d2);
    });

    return results;
  }

  // ---------------- PREVIEW RESULT CARDS ----------------

  Widget buildResultWidgets(List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((d) => CampusSymbolCard(data: d)).toList(),
    );
  }

  // ---------------- GEMINI — CONTEXT LOCKED TO FIRESTORE ----------------

  Future<String> summarizeFromCampusData(
      String question, List<Map<String, dynamic>> items) async {
    final contextText = items.map((d) {
      return """
Title: ${d['title']}
Type: ${d['type']}
Description: ${d['description']}
""";
    }).join("\n---\n");

    try {
      final res = await http.post(
        Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/"
          "gemini-flash-latest:generateContent?key=$geminiApiKey",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
You are OneCummins Campus Assistant.

Answer ONLY using the Firestore campus data provided.
Do NOT use external information.
If the answer is missing, say it is not available.

User Question:
$question

Campus Data:
$contextText
"""
                }
              ]
            }
          ]
        }),
      );

      final json = jsonDecode(res.body);

      return json["candidates"][0]["content"]["parts"][0]["text"] ??
          "No further details available.";
    } catch (e) {
      return "Error generating explanation: $e";
    }
  }

  // ---------------- SEND MESSAGE FLOW ----------------

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(fromUser: true, text: text));
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    final matches = await _queryCampusItems(text);

    if (matches.isNotEmpty) {
      // Show widget preview cards
      _messages.add(
        ChatMessage(fromUser: false, widget: buildResultWidgets(matches)),
      );

      // AI summary based ONLY on those cards
      final summary = await summarizeFromCampusData(text, matches);

      _messages.add(ChatMessage(fromUser: false, text: summary));
    } else {
      _messages.add(const ChatMessage(
        fromUser: false,
        text: "No matching campus item was found in the system right now 📭",
      ));
    }

    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  // ---------------- SCROLL ----------------

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OneCummins AI"),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.bgLight,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, i) {
                if (_isTyping && i == _messages.length) {
                  return const ChatBubble(
                    text: "AI is typing...",
                    fromUser: false,
                  );
                }

                final msg = _messages[i];

                if (msg.widget != null) return msg.widget!;

                return ChatBubble(
                  text: msg.text ?? "",
                  fromUser: msg.fromUser,
                );
              },
            ),
          ),

          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: "Ask about forms, exams, notices, events...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              color: AppColors.teal,
              onPressed: _isTyping ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- CHAT MODELS ----------------

class ChatMessage {
  final bool fromUser;
  final String? text;
  final Widget? widget;

  const ChatMessage({required this.fromUser, this.text, this.widget});
}

class ChatBubble extends StatelessWidget {
  final bool fromUser;
  final String text;

  const ChatBubble({
    super.key,
    required this.text,
    required this.fromUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              fromUser ? AppColors.teal.withOpacity(0.18) : AppColors.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textDark),
        ),
      ),
    );
  }
}

// ---------------- CAMPUS PREVIEW CARD ----------------

class CampusSymbolCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const CampusSymbolCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');

    final type = (data['type'] ?? '').toString().toLowerCase();
    final accent = _accentColor(type);
    final icon = _iconForType(type);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              accent.withOpacity(0.9),
              AppColors.teal.withOpacity(0.8),
            ],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                (data['type'] ?? '').toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: accent,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                data['description'] ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textDark,
                ),
              ),

              if (data['startDate'] != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      df.format((data['startDate'] as Timestamp).toDate()),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _accentColor(String type) {
    if (type.contains('event')) return AppColors.orange;
    if (type.contains('hackathon')) return AppColors.purple;
    if (type.contains('notice')) return AppColors.teal;
    return AppColors.lime;
  }

  IconData _iconForType(String type) {
    if (type.contains('event')) return Icons.event;
    if (type.contains('hackathon')) return Icons.code;
    if (type.contains('notice')) return Icons.campaign;
    return Icons.info_outline;
  }
}
