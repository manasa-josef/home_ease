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
  final String _huggingFaceToken = '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'; // Replace with your token

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

        // Debug prints for response
        print('Raw Response: ${response.body}');
        print('Decoded Response: $responseData');

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
      appBar: AppBar(
        title: Text('Home Maintenance AI'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          if (_isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: CircularProgressIndicator(),
            )
          ],
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isUserMessage = message['type'] == 'user';
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message['text'] ?? '',
          style: TextStyle(
            color: isUserMessage ? Colors.blue[900] : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Ask a home maintenance question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _isLoading ? null : _sendMessage,
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _isLoading
                ? null
                : () => _sendMessage(_textController.text),
          ),
        ],
      ),
    );
  }
}
