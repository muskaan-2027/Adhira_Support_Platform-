import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../screens/post_detail_screen.dart';
import '../screens/public_profile_screen.dart';
import '../utils/image_helper.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onMarkRead;

  const PostCard({super.key, required this.post, this.onMarkRead});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likesCount;
  bool _loadingAction = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _isLiked = widget.post.likes.contains(user?.id);
    _likesCount = widget.post.likes.length;
  }

  Color _urgencyColor(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'red':
        return Colors.red.shade50;
      case 'yellow':
        return Colors.orange.shade50;
      case 'green':
      default:
        return Colors.white;
    }
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Future<void> _toggleLike() async {
    if (_loadingAction) return;
    setState(() => _loadingAction = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;

      if (_isLiked) {
        await ApiService.unlikePost(token, widget.post.id);
        setState(() {
          _isLiked = false;
          _likesCount--;
        });
      } else {
        await ApiService.likePost(token, widget.post.id);
        setState(() {
          _isLiked = true;
          _likesCount++;
        });
      }
    } catch (e) {
      if (mounted) NotificationService.showMessage(context, "Failed to toggle like");
    } finally {
      if (mounted) setState(() => _loadingAction = false);
    }
  }

  Future<void> _markAsRead() async {
    if (_loadingAction) return;
    setState(() => _loadingAction = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;
      await ApiService.markPostRead(token, widget.post.id);
      widget.onMarkRead?.call();
    } catch (e) {
      if (mounted) NotificationService.showMessage(context, "Failed to mark as read");
    } finally {
      if (mounted) setState(() => _loadingAction = false);
    }
  }

  Future<void> _acceptPrivateRequest() async {
     if (_loadingAction) return;
     setState(() => _loadingAction = true);
     try {
       final token = context.read<AuthService>().token;
       if (token == null) return;
       await ApiService.acceptPrivateRequest(token, widget.post.id);
       if (!mounted) return;
       NotificationService.showMessage(context, "Request accepted. You can view the chat in sessions.");
     } catch(e) {
       if (mounted) NotificationService.showMessage(context, "Failed to accept request");
     } finally {
       if (mounted) setState(() => _loadingAction = false);
     }
  }

  /// Builds an image widget from base64 data or a network URL.
  Widget? _buildMedia() {
    final url = widget.post.mediaUrl;
    if (url.isEmpty || widget.post.mediaType != 'image') return null;

    Widget image = Image(
      image: getImageProvider(url),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: image,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.read<AuthService>().currentUser?.role;

    if (widget.post.isDeleted) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Deleted due to unethical content.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      );
    }

    final mediaWidget = _buildMedia();

    return Card(
      color: (widget.post.urgencyColor.toLowerCase() == 'red')
              ? Colors.red.shade50
              : (widget.post.user?['role'] == 'volunteer'
                  ? Colors.lightBlue.shade50
                  : _urgencyColor(widget.post.urgencyColor)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Repost banner
            if (widget.post.isRepost && widget.post.originalAuthorName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.repeat, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Reposted from ${widget.post.originalAuthorName}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

            // Header row: avatar + name + time
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: widget.post.isAnonymous
                      ? null
                      : () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: widget.post.user?['_id'] ?? ''))),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: widget.post.user?['profilePhoto'] != null && !widget.post.isAnonymous
                        ? getImageProvider(widget.post.user!['profilePhoto'])
                        : null,
                    child: (widget.post.user?['profilePhoto'] == null || widget.post.isAnonymous)
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: widget.post.isAnonymous
                                  ? null
                                  : () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: widget.post.user?['_id'] ?? ''))),
                              child: Text(
                                widget.post.isAnonymous ? 'Anonymous' : (widget.post.user?['name'] ?? 'Unknown User'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (widget.post.mode == 'private') ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.lock, size: 14, color: Colors.grey),
                          ],
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(widget.post.createdAt),
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                      if (widget.post.user?['role'] == 'volunteer' && !widget.post.isAnonymous)
                        Text(
                          'Volunteer',
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Content text
            if (widget.post.content.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                widget.post.content,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ],

            // Image media
            if (mediaWidget != null) ...[
              const SizedBox(height: 10),
              mediaWidget,
            ],

            // Caption (usually for image posts)
            if (widget.post.caption.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.post.caption,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
              ),
            ],

            // Chips
            if (widget.post.field.isNotEmpty || widget.post.urgencyColor.toLowerCase() != 'green') ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (widget.post.field.isNotEmpty)
                    Chip(
                      label: Text(widget.post.field, style: const TextStyle(fontSize: 11, color: Colors.blue)),
                      backgroundColor: Colors.blue.shade50,
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  if (widget.post.urgencyColor.toLowerCase() != 'green')
                    Chip(
                      label: Text(
                        'Urgency: ${widget.post.urgencyColor.toUpperCase()}',
                        style: TextStyle(fontSize: 11, color: widget.post.urgencyColor.toLowerCase() == 'red' ? Colors.red : Colors.orange),
                      ),
                      backgroundColor: widget.post.urgencyColor.toLowerCase() == 'red' ? Colors.red.shade100 : Colors.orange.shade100,
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],

            const SizedBox(height: 10),

            // Actions row
            Row(
              children: [
                // Comment count
                InkWell(
                  onTap: () {
                    final token = context.read<AuthService>().token;
                    if (token != null) ApiService.incrementView(token, widget.post.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PostDetailScreen(post: widget.post)),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        widget.post.commentCount > 0 ? '${widget.post.commentCount}' : 'Reply',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Like
                InkWell(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text('$_likesCount', style: TextStyle(color: _isLiked ? Colors.red : Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Views
                if (widget.post.views > 0) ...[
                  Icon(Icons.visibility_outlined, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text('${widget.post.views}', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ],
                const Spacer(),
                if (widget.post.urgencyColor.toLowerCase() == 'red' && widget.onMarkRead != null) ...[
                  TextButton.icon(
                    onPressed: _loadingAction ? null : _markAsRead,
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark as Read', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (widget.post.mode == 'private' && userRole == 'volunteer')
                  ElevatedButton(
                    onPressed: _loadingAction ? null : _acceptPrivateRequest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      minimumSize: const Size(0, 30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loadingAction
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Accept', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
