import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'private_chat_screen.dart';

class PrivateSessionsScreen extends StatefulWidget {
  const PrivateSessionsScreen({super.key});

  @override
  State<PrivateSessionsScreen> createState() => _PrivateSessionsScreenState();
}

class _PrivateSessionsScreenState extends State<PrivateSessionsScreen> {
  bool _loading = false;
  List<dynamic> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;
      
      final res = await ApiService.getPrivateSessions(token);
      setState(() {
        _sessions = res['sessions'] ?? [];
      });
    } catch (e) {
      if (mounted) NotificationService.showMessage(context, "Failed to load sessions");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.read<AuthService>().currentUser?.role;

    return Scaffold(
      appBar: AppBar(title: const Text('Private Chats')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(child: Text("No private chats yet."))
              : ListView.builder(
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    // If user is volunteer, show helpseeker name. If user is helpseeker, show volunteer name.
                    final otherUser = userRole == 'volunteer' ? session['helpSeekerId'] : session['volunteerId'];
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.shade100,
                        child: const Icon(Icons.lock, color: Colors.purple),
                      ),
                      title: Text(otherUser?['name'] ?? 'Unknown User'),
                      subtitle: const Text('Tap to open chat...'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrivateChatScreen(
                              sessionId: session['_id'],
                              otherUserName: otherUser?['name'] ?? 'Unknown User',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
