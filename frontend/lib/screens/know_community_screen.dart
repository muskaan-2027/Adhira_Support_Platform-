import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/user_shell_layout.dart';
import 'chatbot_screen.dart';
import 'community_stories_screen.dart';
import 'profile_screen.dart';
import 'safety_apps_screen.dart';
import '../utils/nav_helper.dart';
import 'user_dashboard_screen.dart';
import 'volunteer_dashboard_screen.dart';

class KnowCommunityScreen extends StatefulWidget {
  const KnowCommunityScreen({super.key});

  @override
  State<KnowCommunityScreen> createState() => _KnowCommunityScreenState();
}

class _KnowCommunityScreenState extends State<KnowCommunityScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  bool _loadingBlogs = true;
  List<dynamic> _blogs = [];

  final List<Map<String, dynamic>> _safetyApps = [
    {
      'name': 'bSafe',
      'icon': Icons.security_rounded,
      'color': const Color(0xFF7B61FF),
      'desc': 'Personal safety app with SOS & live location.',
      'rating': '4.6',
      'url': 'https://play.google.com/store/apps/details?id=com.bsafe',
    },
    {
      'name': 'Raksha',
      'icon': Icons.shield_outlined,
      'color': const Color(0xFFE11D48),
      'desc': 'Smart safety app for women\'s security.',
      'rating': '4.4',
      'url': 'https://play.google.com/store/search?q=raksha%20women%20safety&c=apps',
    },
    {
      'name': 'Himmat',
      'icon': Icons.health_and_safety_rounded,
      'color': const Color(0xFFEAB308),
      'desc': 'Quick SOS alerts and real-time tracking.',
      'rating': '4.5',
      'url': 'https://play.google.com/store/search?q=himmat%20app&c=apps',
    },
    {
      'name': 'Circle of 6',
      'icon': Icons.group_rounded,
      'color': const Color(0xFF14B8A6),
      'desc': 'Your trusted circle for safety & support.',
      'rating': '4.3',
      'url': 'https://play.google.com/store/apps/details?id=com.circleof6.v2',
    },
  ];

  late List<Map<String, dynamic>> _filteredApps;

  bool _loadingStories = true;
  List<dynamic> _recentStories = [];

  Future<void> _fetchStories() async {
    setState(() => _loadingStories = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;
      
      final response = await ApiService.getCommunityStories(token);
      if (mounted) {
        setState(() {
          _recentStories = response['stories'] ?? [];
          _loadingStories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStories = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _filteredApps = List.from(_safetyApps);
    _fetchBlogs();
    _fetchStories();
  }

  Future<void> _fetchBlogs([String? query]) async {
    setState(() => _loadingBlogs = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;

      final response = await ApiService.getCommunityBlogs(token, query: query);
      
      if (mounted) {
        setState(() {
          _blogs = response['blogs'] ?? [];
          _loadingBlogs = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch Blogs Error: $e');
      if (mounted) {
        setState(() => _loadingBlogs = false);
      }
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _fetchBlogs(query);
      setState(() {
        final q = query.toLowerCase();
        _filteredApps = _safetyApps.where((app) => 
          app['name'].toString().toLowerCase().contains(q) || 
          app['desc'].toString().toLowerCase().contains(q)
        ).toList();
        if (_filteredApps.isEmpty) {
          _filteredApps = List.from(_safetyApps); // Show all if no match
        }
      });
    } else {
      setState(() {
        _filteredApps = List.from(_safetyApps);
      });
    }
  }

  void _onTagClick(String tag) {
    _searchController.text = tag;
    _onSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'User';

    return UserShellLayout(
      selectedSection: UserNavSection.knowCommunity,
      title: 'Know Your Community',
      subtitle: 'Find support, share experiences, and stay informed.',
      userName: userName,
      accountRole: user?.role == 'volunteer' ? 'Volunteer' : 'User',
      statusText: 'Stay Safe',
      onProfileTap: () => NavHelper.replaceWith(context, const ProfileScreen()),
      onLogout: () => context.read<AuthService>().logout(),
      onBackTap: () {
        if (user?.role == 'volunteer') {
          NavHelper.replaceWith(context, VolunteerDashboardScreen());
        } else {
          NavHelper.replaceWith(context, UserDashboardScreen());
        }
      },
      navItems: NavHelper.getNavItems(context, user),
      child: Column(
        children: [
          _buildSearchSection(),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              if (isWide) {
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildBlogsCard()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildAppsCard()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildShareStoryCard()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildRecentStoriesCard()),
                      ],
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildBlogsCard(),
                  const SizedBox(height: 24),
                  _buildAppsCard(),
                  const SizedBox(height: 24),
                  _buildShareStoryCard(),
                  const SizedBox(height: 24),
                  _buildRecentStoriesCard(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search for your problem',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x05000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 20, right: 12),
                        child: Icon(Icons.search_rounded, color: AppColors.textMuted),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (_) => _onSearch(),
                          decoration: const InputDecoration(
                            hintText: 'E.g. harassment, stalking, safety in public transport...',
                            hintStyle: TextStyle(color: AppColors.textMuted),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          onPressed: _onSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                          child: const Text('Search'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Popular searches:',
                      style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    _buildSearchTag('Harassment'),
                    _buildSearchTag('Stalking'),
                    _buildSearchTag('Online Abuse'),
                    _buildSearchTag('Safety in Public Places'),
                    _buildSearchTag('Cyber Safety'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Placeholder for the illustration
          Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEDE7FF),
            ),
            child: const Icon(
              Icons.manage_search_rounded,
              size: 70,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTag(String tag) {
    return InkWell(
      onTap: () => _onTagClick(tag),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2EEFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          tag,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBlogsCard() {
    final blogs = _blogs.where((b) => (b['type'] ?? '').toString().toLowerCase() == 'blog').toList();
    final articles = _blogs.where((b) => (b['type'] ?? '').toString().toLowerCase() == 'article').toList();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Blogs & Articles',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              Text(
                'View All',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loadingBlogs)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_blogs.isEmpty)
            const Text('No articles found.', style: TextStyle(color: AppColors.textMuted))
          else ...[
            if (blogs.isNotEmpty) ...[
              const Text('Blogs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...blogs.map((blog) => _buildBlogItem(blog)),
              const SizedBox(height: 24),
            ],
            if (articles.isNotEmpty) ...[
              const Text('Articles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...articles.map((article) => _buildBlogItem(article)),
            ],
          ]
        ],
      ),
    );
  }

  void _showBlogDialog(dynamic blog) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(blog['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(
              blog['content'] ?? '',
              style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF4B5563)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlogItem(dynamic blog) {
    return InkWell(
      onTap: () {
        debugPrint('Blog clicked: ${blog['title']}');
        if (blog['url'] != null && blog['url'].toString().isNotEmpty) {
          debugPrint('Launching URL: ${blog['url']}');
          _launchUrl(blog['url']);
        } else if (blog['content'] != null && blog['content'].toString().isNotEmpty) {
          debugPrint('Showing content dialog');
          _showBlogDialog(blog);
        } else {
          debugPrint('No URL or content found for this blog');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.article_rounded, color: Color(0xFF2166D8), size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    blog['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EEFF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          blog['category'] ?? 'General',
                          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Row(
                        children: [
                          if (blog['content'] != null || blog['url'] != null) ...[
                            const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            blog['date'] ?? '',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildAppsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Other Safety Apps',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              InkWell(
                onTap: () => NavHelper.replaceWith(context, const SafetyAppsScreen()),
                child: const Text(
                  'View All',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Explore other apps that can help keep you safe.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _filteredApps.map((app) => _buildAppItem(app)).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $urlString')),
          );
        }
      }
    } catch (e) {
      debugPrint('Launch URL Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening the website.')),
        );
      }
    }
  }

  Widget _buildAppItem(Map<String, dynamic> app) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: app['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(app['icon'], color: app['color'], size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                app['name'],
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                app['desc'],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    app['rating'],
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 16),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _launchUrl(app['url']),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('View'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareStoryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share Your Story',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your story can inspire and help others.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEDE7FF),
                ),
                child: const Icon(Icons.favorite_rounded, size: 60, color: AppColors.primary),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildStoryBullet(Icons.campaign_rounded, 'Inspire Others', 'Your experience can give hope to someone.'),
                    _buildStoryBullet(Icons.diversity_1_rounded, 'Raise Awareness', 'Help build a safer and stronger community.'),
                    _buildStoryBullet(Icons.shield_rounded, 'Protect Identities', 'You can choose to stay anonymous.'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openShareStoryDialog,
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Share Your Story'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoryBullet(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStoriesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Stories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              InkWell(
                onTap: () => NavHelper.replaceWith(context, const CommunityStoriesScreen()),
                child: const Text(
                  'View All',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loadingStories)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_recentStories.isEmpty)
            const Text('No stories yet. Be the first to share yours!', style: TextStyle(color: AppColors.textMuted))
          else
            ..._recentStories.take(3).map((story) => _buildStoryItem(story)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your voice matters. Your story can be the light for someone else.',
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(dynamic story) {
    final title = story['title'] ?? 'Untitled';
    final snippet = story['snippet'] ?? '';
    final anonymous = story['anonymous'] ?? false;
    final userName = anonymous ? 'Anonymous' : (story['userId']?['name'] ?? 'User');
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    
    // Format date roughly (could use intl package for better formatting)
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(initial, style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(timeAgo, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Text(snippet, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: () async {
                  try {
                    final token = context.read<AuthService>().token;
                    if (token == null) return;
                    await ApiService.toggleStoryLike(token, story['_id']);
                    _fetchStories(); // refresh
                  } catch (_) {}
                },
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                      size: 16, 
                      color: isLiked ? Colors.red : AppColors.textSecondary
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${likes.length}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openShareStoryDialog() {
    final titleCtrl = TextEditingController();
    final storyCtrl = TextEditingController();
    bool isAnonymous = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Share Your Story'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: storyCtrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Your Story',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Post Anonymously'),
                      value: isAnonymous,
                      onChanged: (val) {
                        setDialogState(() {
                          isAnonymous = val ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty || storyCtrl.text.trim().isEmpty) return;
                    
                    try {
                      final token = context.read<AuthService>().token;
                      if (token == null) return;

                      Navigator.pop(context); // Close dialog

                      // Show loading snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing your story...')),
                      );

                      await ApiService.createCommunityStory(
                        token,
                        titleCtrl.text.trim(),
                        storyCtrl.text.trim(),
                        isAnonymous,
                      );

                      _fetchStories(); // Refresh stories list

                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to share story.')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Share'),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
