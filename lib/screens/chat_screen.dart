import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? userData;
  final String huggingFaceToken;
  final String modelEndpoint;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userData,
    required this.huggingFaceToken,
    required this.modelEndpoint,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _chatMessages = [];
  bool isChatLoading = false;

  @override
  void initState() {
    super.initState();
    _chatMessages.add({
      'role': 'assistant',
      'content': 'Hello! I\'m your nutrition expert assistant. How can I help you with your meal planning today?',
      'timestamp': DateTime.now(),
    });
  }

  Future<String> _sendToHuggingFace(String message) async {
    final url = Uri.parse(widget.modelEndpoint);

    final headers = {
      'Authorization': 'Bearer ${widget.huggingFaceToken}',
      'Content-Type': 'application/json',
    };

    final prompt = _buildChatPrompt(message);

    final body = {
      'inputs': prompt,
      'parameters': {
        'max_new_tokens': 300,
        'temperature': 0.7,
        'top_p': 0.9,
        'do_sample': true,
        'return_full_text': false,
      }
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle DeepSeek response format
        if (data is List && data.isNotEmpty) {
          final firstItem = data[0];
          if (firstItem is Map && firstItem.containsKey('generated_text')) {
            return _cleanResponse(firstItem['generated_text'] as String);
          }
        } else if (data is Map && data.containsKey('generated_text')) {
          return _cleanResponse(data['generated_text'] as String);
        }
        throw Exception('Unexpected response format: $data');
      } else if (response.statusCode == 503) {
        // Model is loading
        throw Exception('Model is loading. Please try again in a few moments.');
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  String _cleanResponse(String response) {
    // Remove any repetition or unwanted text
    return response.trim();
  }

  String _buildChatPrompt(String message) {
    if (widget.userData == null) return message;

    return '''
[INST] You are a nutrition expert assistant for a fitness app called RepEat. 
The user has the following profile:
- Goal: ${widget.userData!['goal'] ?? 'Not specified'}
- Diet Preference: ${widget.userData!['diet_preference'] ?? 'Not specified'}
- Allergies: ${widget.userData!['allergies']?.isNotEmpty == true ? widget.userData!['allergies'] : 'None'}

User question: "$message"

Provide helpful, accurate, and personalized nutrition advice based on their profile.
Keep responses concise but informative (150-200 words max).
Focus on practical suggestions they can implement. [/INST]

Assistant: ''';
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      isChatLoading = true;
      _chatMessages.add({
        'role': 'user',
        'content': message,
        'timestamp': DateTime.now(),
      });
    });

    _scrollToBottom();

    try {
      final thinkingMessageIndex = _chatMessages.length;
      _chatMessages.add({
        'role': 'assistant',
        'content': 'Thinking...',
        'timestamp': DateTime.now(),
      });
      setState(() {});

      final response = await _sendToHuggingFace(message);

      setState(() {
        _chatMessages[thinkingMessageIndex]['content'] = response;
      });
    } catch (e) {
      setState(() {
        _chatMessages.last['content'] = 'Sorry, I encountered an error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isChatLoading = false;
      });
      _scrollToBottom();
    }
  }

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

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    final isThinking = message['content'] == 'Thinking...';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.restaurant, size: 16, color: Colors.white),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.deepPurple : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: isThinking
                      ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Thinking...'),
                    ],
                  )
                      : Text(
                    message['content'],
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                if (message['timestamp'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('HH:mm').format(message['timestamp']),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser)
            const SizedBox(width: 8),
          if (isUser)
            const CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 16),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Nutrition Assistant'),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_chatMessages[index]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Ask about nutrition, recipes, or meal planning...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (value) {
                      if (!isChatLoading) {
                        _sendChatMessage(value);
                        _chatController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: isChatLoading ? Colors.grey : Colors.deepPurple,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: isChatLoading
                        ? null
                        : () {
                      if (_chatController.text.trim().isNotEmpty) {
                        _sendChatMessage(_chatController.text);
                        _chatController.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
//