import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/post_card.dart';
import 'chatbot_screen.dart';
import 'need_guidance_screen.dart';
import 'notifications_screen.dart';
import '../utils/nav_helper.dart';
import '../utils/image_helper.dart';
import 'user_dashboard_screen.dart';
import 'volunteer_dashboard_screen.dart';
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _contentController = TextEditingController();
  final _captionController = TextEditingController();
  final _fieldController = TextEditingController();
  bool _isAnonymous = false;
  String _mode = 'public';
  bool _loading = false;
  List<PostModel> _posts = [];
  
  String _mediaBase64 = '';
  String _mediaType = 'text';

  // Selected Tab index
  int _selectedTab = 0; // 0 = All Posts, 1 = Following, 2 = Urgent

  // Color Palette matches the reference
  final Color bgColor = const Color(0xFFF8F5FF);
  final Color primaryTextColor = const Color(0xFF332927);
  final Color postButtonColor = const Color(0xFF2C2522);
  final Color safetyTipsColor = const Color(0xFFFBECE6);
  final Color selectedTabColor = const Color(0xFFDE8F7E);

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _isAnonymous = user?.isAnonymous == true;
    _loadPosts();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _captionController.dispose();
    _fieldController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');
      
      String? tabParam;
      if (_selectedTab == 1) tabParam = 'following';
      if (_selectedTab == 2) tabParam = 'urgent';
      
      final response = await ApiService.getPosts(token, tab: tabParam);
      final list = response['posts'] as List<dynamic>? ?? [];
      setState(() {
        _posts = list
            .whereType<Map<String, dynamic>>()
            .map(PostModel.fromJson)
            .toList();
      });
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(
        context,
        err.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _mediaBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        _mediaType = 'image';
      });
      _showPostModal();
    }
  }

  void _removeMedia() {
    setState(() {
      _mediaBase64 = '';
      _mediaType = 'text';
    });
  }

  Future<void> _createPost() async {
    final content = _contentController.text.trim();
    final caption = _captionController.text.trim();
    
    if (content.isEmpty && _mediaBase64.isEmpty && caption.isEmpty) {
       NotificationService.showMessage(context, 'Please add some content, an image, or a caption to post.');
       return;
    }

    // Set loading indicator in post button
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator())
      );
    }

    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');

      final textToAnalyze = content.isNotEmpty ? content : caption;
      Map<String, dynamic> analysis = {};
      try {
        if (textToAnalyze.trim().isNotEmpty) {
           analysis = await ApiService.analyzePost(token, content: textToAnalyze);
        }
      } catch (e) {
        // Silently ignore frontend analysis failure so the user can still post
      }

      final actions = (analysis['suggestedActions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      final distressLevel = analysis['distressLevel']?.toString() ?? 'normal';

      if (!mounted) return;
      Navigator.pop(context); // close loading dialog

      if (actions.isNotEmpty && distressLevel != 'normal') {
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Distress detected: $distressLevel'),
            content: const Text(
              'Your post may indicate distress. Choose support before publishing.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'chatbot'),
                child: const Text('Open Chatbot'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'volunteer'),
                child: const Text('Volunteer Help'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'publish'),
                style: ElevatedButton.styleFrom(backgroundColor: postButtonColor),
                child: const Text('Publish to Feed', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (!mounted) return;

        if (action == 'chatbot') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          );
          return;
        }

        if (action == 'volunteer') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NeedGuidanceScreen()),
          );
          return;
        }

        if (action != 'publish') return;
      }

      await ApiService.createPost(
        token,
        content: content,
        isAnonymous: _isAnonymous,
        mode: _mode,
        field: _fieldController.text.trim(),
        caption: caption,
        mediaUrl: _mediaBase64,
        mediaType: _mediaType
      );

      _contentController.clear();
      _captionController.clear();
      _fieldController.clear();
      _removeMedia();
      FocusScope.of(context).unfocus();

      await _loadPosts();
      
      if (!mounted) return;
      NotificationService.showMessage(context, 'Post published successfully');

    } catch (err) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context); // close loading dialog
      NotificationService.showMessage(
        context,
        err.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _showPostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final userRole = context.read<AuthService>().currentUser?.role ?? '';
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Create Post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_mediaType == 'text')
                      TextField(
                        controller: _contentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Share what\'s happening...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      )
                    else ...[
                      // Media Preview
                      Stack(
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade200,
                            ),
                            child: _mediaType == 'image' && _mediaBase64.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    base64Decode(_mediaBase64.split(',').last),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Center(child: Icon(Icons.audiotrack, size: 50, color: Colors.grey)),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () {
                                  _removeMedia();
                                  setModalState(() {});
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _captionController,
                        decoration: InputDecoration(
                          hintText: 'Write a caption...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      )
                    ],

                    const SizedBox(height: 16),
                    
                    // Toolbar
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.image, color: selectedTabColor),
                          tooltip: 'Add Photo',
                          onPressed: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                            if (pickedFile != null) {
                              final bytes = await pickedFile.readAsBytes();
                              setModalState(() {
                                _mediaBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                                _mediaType = 'image';
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.mic, color: selectedTabColor),
                          tooltip: 'Add Audio (Coming Soon)',
                          onPressed: () {
                            NotificationService.showMessage(context, 'Audio recording coming soon!');
                          },
                        ),
                      ],
                    ),
                    const Divider(),

                    // Visibility Options
                    if (userRole == 'user') ...[
                      Row(
                        children: [
                          const Text('Mode:', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _mode,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'public', child: Text('Public')),
                              DropdownMenuItem(value: 'private', child: Text('Private')),
                            ],
                            onChanged: (val) => setModalState(() => _mode = val!),
                          ),
                          const Spacer(),
                          const Text('Anonymous:', style: TextStyle(fontWeight: FontWeight.w500)),
                          Switch(
                            value: _isAnonymous,
                            activeColor: selectedTabColor,
                            onChanged: (value) => setModalState(() => _isAnonymous = value),
                          ),
                        ],
                      ),
                      if (_mode == 'private')
                        TextField(
                          controller: _fieldController,
                          decoration: InputDecoration(
                            hintText: 'Specific Field (e.g., #DomesticViolence)',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      const SizedBox(height: 16),
                    ] else if (userRole == 'volunteer') ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Posting Publicly as Volunteer', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                      ),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _createPost();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: postButtonColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 14)
                        ),
                        child: const Text('Post', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                final user = context.read<AuthService>().currentUser;
                if (user?.role == 'volunteer') {
                  NavHelper.replaceWith(context, const VolunteerDashboardScreen());
                } else {
                  NavHelper.replaceWith(context, const UserDashboardScreen());
                }
              }
            },
          ),
          // Custom Title Image Placeholder
          Expanded(
            child: Image.asset(
              'assets/community_title.png',
              height: 60,
              alignment: Alignment.centerLeft,
              errorBuilder: (context, error, stackTrace) {
                 // Fallback if image not found
                 return Text(
                   'Community', 
                   style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 32, fontWeight: FontWeight.bold, color: primaryTextColor)
                 );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black87),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePostCard() {
    final user = context.read<AuthService>().currentUser;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE6E1), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
               CircleAvatar(
                 radius: 22,
                 backgroundColor: const Color(0xFFF2E2D8),
                backgroundImage: user?.profilePhoto != null ? getImageProvider(user!.profilePhoto!) : null,
                 child: user?.profilePhoto == null ? Icon(Icons.person, color: selectedTabColor) : null,
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: InkWell(
                   onTap: _showPostModal,
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(24),
                       border: Border.all(color: Colors.grey.shade200),
                     ),
                     child: Text(
                       'Share what\'s happening...',
                       style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                     ),
                   ),
                 ),
               ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              InkWell(
                onTap: () {
                   setState(() => _mode = _mode == 'public' ? 'private' : 'public');
                },
                child: Row(
                  children: [
                    Icon(Icons.language, size: 18, color: primaryTextColor),
                    const SizedBox(width: 4),
                    Text('Public', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              InkWell(
                onTap: () {
                  setState(() => _isAnonymous = !_isAnonymous);
                },
                child: Row(
                  children: [
                    Icon(_isAnonymous ? Icons.lock : Icons.lock_open, size: 18, color: primaryTextColor),
                    const SizedBox(width: 4),
                    Text('Anonymous', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _showPostModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: postButtonColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  elevation: 0,
                ),
                child: const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final currentUserId = context.read<AuthService>().currentUser?.id ?? '';
    int urgentCount = _posts.where((p) => p.urgencyColor.toLowerCase() == 'red' && !p.readBy.contains(currentUserId)).length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTabItem(0, 'All Posts'),
          const SizedBox(width: 24),
          _buildTabItem(1, 'Following'),
          const SizedBox(width: 24),
          _buildTabItem(2, 'Urgent', badgeCount: urgentCount),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title, {int? badgeCount}) {
    bool isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedTab = index);
        _loadPosts(); // Reload posts when tab changes
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? primaryTextColor : Colors.grey.shade500,
                  fontSize: 15,
                ),
              ),
              if (badgeCount != null && badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 30,
            decoration: BoxDecoration(
              color: isSelected ? selectedTabColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().currentUser?.id ?? '';
    List<PostModel> displayPosts = _posts;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildTopHeader(),
          _buildTabs(),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
              ? Center(child: CircularProgressIndicator(color: selectedTabColor))
              : displayPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.spa, size: 80, color: selectedTabColor.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text('A safe space for everyone.', style: TextStyle(fontSize: 18, fontFamily: 'PlayfairDisplay')),
                          const SizedBox(height: 8),
                          const Text('Be the first to share a post.'),
                        ],
                      )
                    )
                  : RefreshIndicator(
                      color: selectedTabColor,
                      onRefresh: _loadPosts,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 0, bottom: 20),
                        itemCount: displayPosts.length,
                        itemBuilder: (context, index) {
                          final p = displayPosts[index];
                          return PostCard(
                            post: p,
                            onMarkRead: () {
                              setState(() {
                                _posts.removeWhere((item) => item.id == p.id);
                              });
                            },
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPostModal,
        backgroundColor: postButtonColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
