import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class PrivateChatScreen extends StatefulWidget {
  final String sessionId;
  final String otherUserName;

  const PrivateChatScreen({super.key, required this.sessionId, required this.otherUserName});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  bool _loading = false;
  List<dynamic> _messages = [];
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;

      final res = await ApiService.getPrivateMessages(token, widget.sessionId);
      setState(() {
        _messages = res['messages'] ?? [];
      });
    } catch (e) {
      if (mounted) NotificationService.showMessage(context, "Failed to load messages");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;

      _messageController.clear();
      await ApiService.sendPrivateMessage(token, widget.sessionId, text);
      await _loadMessages();
    } catch (e) {
      if (mounted) NotificationService.showMessage(context, "Failed to send message");
    }
  }

  Color _urgencyColor(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'red':
        return Colors.red.shade200;
      case 'yellow':
        return Colors.orange.shade200;
      case 'green':
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUserName)),
      body: Column(
        children: [
          Expanded(
            child: _loading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final isMe = m['senderId']?['_id'] == currentUserId;
                      
                      final content = m['isDeleted'] == true
                          ? 'Deleted due to unethical content.'
                          : m['content'];
                          
                      final uColor = _urgencyColor(m['urgencyColor'] ?? 'green');

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                            border: uColor != Colors.transparent ? Border.all(color: uColor, width: 2) : null,
                          ),
                          child: Text(
                            content,
                            style: TextStyle(
                               fontStyle: m['isDeleted'] == true ? FontStyle.italic : FontStyle.normal,
                               color: m['isDeleted'] == true ? Colors.grey : Colors.black
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
