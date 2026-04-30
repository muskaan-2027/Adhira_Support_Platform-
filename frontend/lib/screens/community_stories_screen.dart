import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class CommunityStoriesScreen extends StatefulWidget {
  const CommunityStoriesScreen({super.key});

  @override
  State<CommunityStoriesScreen> createState() => _CommunityStoriesScreenState();
}

class _CommunityStoriesScreenState extends State<CommunityStoriesScreen> {
  bool _loading = true;
  List<dynamic> _stories = [];

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;
      
      final response = await ApiService.getCommunityStories(token);
      if (mounted) {
        setState(() {
          _stories = response['stories'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Stories'),
        actions: [
          IconButton(
            onPressed: _fetchStories,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stories.isEmpty
              ? const Center(child: Text('No stories found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _stories.length,
                  itemBuilder: (context, index) {
                    final story = _stories[index];
                    return _buildStoryCard(story);
                  },
                ),
    );
  }

  Widget _buildStoryCard(dynamic story) {
    final title = story['title'] ?? 'Untitled';
    final snippet = story['snippet'] ?? '';
    final anonymous = story['anonymous'] ?? false;
    final userName = anonymous ? 'Anonymous' : (story['userId']?['name'] ?? 'User');
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    
    final dateStr = story['createdAt'] ?? '';
    String timeAgo = 'Just now';
    if (dateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(dateStr);
        final diff = DateTime.now().difference(date);
        if (diff.inDays > 0) {
          timeAgo = '${diff.inDays} d ago';
        } else if (diff.inHours > 0) {
          timeAgo = '${diff.inHours} h ago';
        } else if (diff.inMinutes > 0) {
          timeAgo = '${diff.inMinutes} m ago';
        }
      } catch (_) {}
    }

    final likes = List<String>.from(story['likes'] ?? []);
    final currentUserId = context.read<AuthService>().currentUser?.id;
    final isLiked = currentUserId != null && likes.contains(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {}, // Can be extended to view full story
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B61FF), Color(0xFF9F8CFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                timeAgo,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: InkWell(
                        onTap: () async {
                          try {
                            final token = context.read<AuthService>().token;
                            if (token == null) return;
                            await ApiService.toggleStoryLike(token, story['_id']);
                            _fetchStories();
                          } catch (_) {}
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                              child: Icon(
                                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                key: ValueKey(isLiked),
                                size: 18,
                                color: isLiked ? const Color(0xFFE11D48) : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${likes.length}',
                              style: TextStyle(
                                color: isLiked ? const Color(0xFFE11D48) : AppColors.textSecondary,
                                fontWeight: isLiked ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  snippet,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
