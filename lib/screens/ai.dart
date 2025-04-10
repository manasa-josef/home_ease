import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIChat extends StatefulWidget {
  @override
  _AIChatState createState() => _AIChatState();
}

class _AIChatState extends State<AIChat> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  // Hugging Face API details
  final String _apiUrl = 'https://api-inference.huggingface.co/models/tiiuae/falcon-7b-instruct';
  final String _huggingFaceToken = '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'; 

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({'type': 'user', 'text': message});
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_huggingFaceToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'inputs': message}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Extract the AI response
        String aiResponse;
        if (responseData is List && responseData.isNotEmpty && responseData[0].containsKey('generated_text')) {
          aiResponse = responseData[0]['generated_text'] ?? 'Sorry, no response.';
        } else {
          aiResponse = 'Unexpected response format.';
        }

        setState(() {
          _messages.add({'type': 'ai', 'text': aiResponse});
        });
      } else {
        setState(() {
          _messages.add({
            'type': 'ai',
            'text': 'Error processing request. Status: ${response.statusCode}, Message: ${response.reasonPhrase}',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'type': 'ai', 'text': 'Network error: $e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Home Maintenance AI', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD8BFD8), Color(0xFFEEEAF7)], // Light lavender gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 80), // Space for AppBar
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isUserMessage = message['type'] == 'user';
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.deepPurple[200] : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: isUserMessage ? Radius.circular(16) : Radius.circular(4),
            bottomRight: isUserMessage ? Radius.circular(4) : Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          message['text'] ?? '',
          style: TextStyle(
            fontSize: 16,
            color: isUserMessage ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    spreadRadius: 1,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Ask a home maintenance question...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  border: InputBorder.none,
                ),
                onSubmitted: _isLoading ? null : _sendMessage,
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}
