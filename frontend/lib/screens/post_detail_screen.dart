import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/post_card.dart';
import '../utils/image_helper.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _loading = false;
  List<dynamic> _comments = [];
  final _commentController = TextEditingController();
  final Color primaryColor = const Color(0xFFCB8980); // Dusty Rose / Coral
  final Color backgroundColor = const Color(0xFFFDFBF7);

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;

      final res = await ApiService.getComments(token, widget.post.id);
      setState(() {
        _comments = res['comments'] ?? [];
      });
    } catch (e) {
      if (mounted) NotificationService.showMessage(context, "Failed to load comments");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;

      await ApiService.addComment(token, widget.post.id, text);
      _commentController.clear();
      FocusScope.of(context).unfocus();
      await _loadComments();
    } catch (e) {
      if (mounted) NotificationService.showMessage(context, "Failed to add comment");
    }
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString.toString());
      return DateFormat('dd MMM yyyy, h:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  PostCard(post: widget.post),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.format_quote, color: primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '"Empowered women empower women. Share your thoughts with kindness."',
                            style: TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: primaryColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _loading
                      ? Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: primaryColor),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final c = _comments[index];
                            if (c['isDeleted'] == true) {
                              return const ListTile(
                                title: Text('Removed due to community guidelines.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: primaryColor.withOpacity(0.2),
                                    backgroundImage: c['userId']?['profilePhoto'] != null
                                        ? getImageProvider(c['userId']['profilePhoto'])
                                        : null,
                                    child: c['userId']?['profilePhoto'] == null 
                                        ? Icon(Icons.person, color: primaryColor, size: 20)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              c['userId']?['name'] ?? 'User',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatDate(c['createdAt']),
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c['content'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _addComment,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
