import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/user_shell_layout.dart';
import '../utils/nav_helper.dart';
import 'chatbot_screen.dart';
import 'community_screen.dart';
import 'help_requests_screen.dart';
import 'profile_screen.dart';
import 'profile_dashboard_screen.dart';
import 'volunteer_profile_screen.dart';
import 'know_community_screen.dart';
import 'public_profile_screen.dart';
import 'dart:async';

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  List<dynamic> _requests = [];
  bool _isLoadingRequests = true;
  List<dynamic> _followRequests = [];
  bool _isLoadingFollowRequests = true;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;
  
  // Search state
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
    _loadFollowInfo();
    _fetchFollowRequests();
  }

  Future<void> _loadFollowInfo() async {
    try {
      final token = context.read<AuthService>().token;
      final userId = context.read<AuthService>().currentUser?.id;
      if (token == null || userId == null) return;
      final info = await ApiService.getFollowInfo(token, userId);
      if (!mounted) return;
      setState(() {
        _followersCount = (info['followers'] as num?)?.toInt() ?? 0;
        _followingCount = (info['following'] as num?)?.toInt() ?? 0;
        _isFollowing = info['isFollowing'] as bool? ?? false;
      });
    } catch (e) {
      // ignore errors, keep zeros
    }
  }
  Future<void> _fetchRequests() async {
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;
      final response = await ApiService.getHelpRequests(token);
      if (mounted) {
        setState(() {
          _requests = response['requests'] ?? [];
          _isLoadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRequests = false);
      }
    }
  }

  Future<void> _fetchFollowRequests() async {
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;
      final response = await ApiService.getFollowRequests(token);
      if (mounted) {
        setState(() {
          _followRequests = response['requests'] ?? [];
          _isLoadingFollowRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFollowRequests = false);
      }
    }
  }

  Future<void> _respondToFollowRequest(String requesterId, String action) async {
    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');
      await ApiService.respondToFollowRequest(token, requesterId, action);
      await _fetchFollowRequests();
      await _loadFollowInfo();
      if (!mounted) return;
      NotificationService.showMessage(context, 'Request ${action}ed');
    } catch (e) {
      if (mounted) NotificationService.showMessage(context, e.toString());
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;
      final response = await ApiService.searchUsers(token, query);
      if (mounted) {
        setState(() {
          _searchResults = response['users'] ?? [];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _sendFollowRequest(String targetId) async {
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;
      final result = await ApiService.followVolunteer(token, targetId);
      if (mounted) {
        NotificationService.showMessage(context, result['message'] ?? 'Request sent');
        // Refresh following info
        _loadFollowInfo();
      }
    } catch (e) {
      if (mounted) NotificationService.showMessage(context, e.toString());
    }
  }

  Future<void> _updateStatus(String requestId, String status) async {
    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');

      String? assistanceNote;
      int hoursSpent = 0;
      int peopleHelped = 0;
      
      if (status == 'completed') {
        final noteController = TextEditingController();
        final hoursController = TextEditingController();
        final peopleController = TextEditingController();
        
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Complete Request'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Assistance Note',
                      hintText: 'Add details about the help provided',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hours Spent',
                      hintText: 'e.g. 2',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: peopleController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'People Helped',
                      hintText: 'e.g. 1',
                    ),
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
                onPressed: () {
                  Navigator.pop(context, {
                    'note': noteController.text.trim(),
                    'hours': int.tryParse(hoursController.text) ?? 0,
                    'people': int.tryParse(peopleController.text) ?? 0,
                  });
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        );

        if (result == null) return;
        assistanceNote = result['note'] as String;
        hoursSpent = result['hours'] as int;
        peopleHelped = result['people'] as int;
      }

      await ApiService.updateHelpRequestStatus(
        token,
        requestId,
        status,
        assistanceNote: assistanceNote,
        hoursSpent: hoursSpent,
        peopleHelped: peopleHelped,
      );
      await _fetchRequests();
      if (!mounted) return;
      NotificationService.showMessage(context, 'Request updated: $status');
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(
        context,
        err.toString().replaceFirst('Exception: ', ''),
      );
    }
  }



  void _openProfile() {
    NavHelper.push(context, const ProfileScreen());
  }

  Future<void> _logout() {
    return context.read<AuthService>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'Volunteer';
    final isActive = user?.volunteerAvailability == 'active';

    return UserShellLayout(
      selectedSection: UserNavSection.dashboard,
      title: 'Welcome back, ${userName.toLowerCase()}!',
      subtitle: 'Your dedication brings hope and safety to many.',
      userName: userName,
      accountRole: 'Volunteer',
      statusText: 'Keep Safe',
      supportHeadline: 'You Make a Difference',
      supportMessage: 'Every action counts towards\na safer society.',
      supportIcon: Icons.groups_rounded,
      onProfileTap: _openProfile,
      onLogout: _logout,
      navItems: NavHelper.getNavItems(context, user),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final profileCol = _profileCard(user, userName, isActive);
          final statsRow = _statsRow();
          final quickActions = _quickActionsCard(context);
          final recentActivity = _recentActivityCard();
          final skills = _skillsCard(user);
          final experience = _experienceCard(user);
          final followersFollowing = _followersFollowingCard();
          final followRequests = _followRequestsCard();
          final connectWithPeople = _connectWithPeopleCard();
          final knowCommunity = _knowCommunityCard();

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _greeting(userName),
                const SizedBox(height: 20),
                profileCol,
                const SizedBox(height: 14),
                connectWithPeople,
                const SizedBox(height: 14),
                knowCommunity,
                const SizedBox(height: 14),
                followRequests,
                const SizedBox(height: 14),
                followersFollowing,
                const SizedBox(height: 14),
                statsRow,
                const SizedBox(height: 14),
                quickActions,
                const SizedBox(height: 14),
                recentActivity,
                const SizedBox(height: 14),
                skills,
                const SizedBox(height: 14),
                experience,
                const SizedBox(height: 20),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _greeting(userName),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Content (Wide)
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        profileCol,
                        const SizedBox(height: 16),
                        connectWithPeople,
                        const SizedBox(height: 16),
                        knowCommunity,
                        const SizedBox(height: 16),
                        followRequests,
                        const SizedBox(height: 16),
                        statsRow,
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: followersFollowing),
                            const SizedBox(width: 16),
                            Expanded(child: skills),
                          ],
                        ),
                        const SizedBox(height: 16),
                        experience,
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Sidebar / Quick Actions (Narrow)
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        quickActions,
                        const SizedBox(height: 16),
                        recentActivity,
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }


  Widget _greeting(String userName) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 4),
      ],
    );
  }

  Widget _profileCard(AppUser? user, String userName, bool isActive) {
    final email = user?.email ?? 'volunteer@example.com';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'V';
    final volunteerId = user?.registrationId ?? 'VOL${user?.id.substring(user.id.length - 6).toUpperCase() ?? "123456"}';
    
    // Calculate profile completion (simple version)
    int completion = 40;
    if (user?.phone?.isNotEmpty == true) completion += 10;
    if (user?.city?.isNotEmpty == true) completion += 10;
    if (user?.skills?.isNotEmpty == true) completion += 10;
    if (user?.volunteerExperience?.isNotEmpty == true) completion += 10;
    if (user?.languagesKnown.isNotEmpty == true) completion += 10;
    if (user?.additionalInfo?.isNotEmpty == true) completion += 10;
    if (completion > 100) completion = 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFFEDE7FF),
                  backgroundImage: user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty
                      ? MemoryImage(base64Decode(user.profilePhoto!))
                      : null,
                  child: user?.profilePhoto == null || user!.profilePhoto!.isEmpty
                      ? Text(initial, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 32))
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24)),
                      const Text('Volunteer', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          volunteerId,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statusChip('Verified', const Color(0xFF188A56), const Color(0xFFEAF8F0)),
                          _statusChip(
                            isActive ? 'Active' : 'Inactive',
                            isActive ? const Color(0xFF188A56) : const Color(0xFFDC284C),
                            isActive ? const Color(0xFFEAF8F0) : const Color(0xFFFFE9EE),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Container(height: 100, width: 1, color: AppColors.border),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Profile Completion', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('$completion%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: completion / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF0EDFF),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Complete your profile to receive more opportunities.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _openProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Update Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(width: 6),
                          Icon(Icons.edit_note, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        if (user?.id != null) {
                          NavHelper.push(context, VolunteerProfileScreen(volunteerId: user!.id));
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View Public', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(width: 6),
                          Icon(Icons.visibility_outlined, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _statusChip(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _quickActionTile(
            title: 'Accept / Reject Requests',
            icon: Icons.fact_check_outlined,
            color: const Color(0xFF9E77ED),
            onTap: () => NavHelper.push(
              context,
              const HelpRequestsScreen(
                isVolunteer: true,
                statusFilter: 'pending',
                title: 'Pending Help Requests',
              ),
            ),
          ),
          _quickActionTile(
            title: 'Provide Assistance',
            icon: Icons.volunteer_activism_outlined,
            color: const Color(0xFF188A56),
            onTap: () => NavHelper.push(
              context,
              const HelpRequestsScreen(
                isVolunteer: true,
                statusFilter: 'accepted',
                title: 'Accepted Requests',
              ),
            ),
          ),
          _quickActionTile(
            title: 'Completed Work',
            icon: Icons.task_alt_rounded,
            color: const Color(0xFFFDB528),
            onTap: () => NavHelper.push(
              context,
              const HelpRequestsScreen(
                isVolunteer: true,
                statusFilter: 'completed',
                title: 'Completed Assistance',
              ),
            ),
          ),
          _quickActionTile(
            title: 'Know Your Community',
            icon: Icons.people_outline_rounded,
            color: const Color(0xFF2166D8),
            onTap: () => NavHelper.push(context, const KnowCommunityScreen()),
          ),
          _quickActionTile(
            title: 'Chatbot Assistant',
            icon: Icons.smart_toy_outlined,
            color: const Color(0xFFEF7B1A),
            onTap: () => NavHelper.push(context, ChatbotScreen()),
          ),
        ],
      ),
    );
  }

  Widget _quickActionTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _followersFollowingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(Icons.people, 'Followers', _followersCount.toString()),
          _statItem(Icons.person_add, 'Following', _followingCount.toString()),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ],
    );
  }


  Widget _statsRow() {
    final completedRequestsList = _requests.where((r) => r['status'] == 'completed').toList();
    final int completedRequests = completedRequestsList.length;
    
    int totalHours = 0;
    int communityImpact = 0;

    for (var r in completedRequestsList) {
      totalHours += (r['hoursSpent'] as num?)?.toInt() ?? 0;
      communityImpact += (r['peopleHelped'] as num?)?.toInt() ?? 0;
    }

    final user = context.watch<AuthService>().currentUser;
    final String ratingStr = user != null && user.averageRating > 0
        ? user.averageRating.toStringAsFixed(1)
        : '0.0';
    final double ratingVal = user?.averageRating ?? 0.0;

    final items = <({
      String title,
      String value,
      String subtitle,
      IconData icon,
      Color color,
      Widget? extra,
    })>[
      (
        title: 'Total Hours',
        value: _isLoadingRequests ? '-' : totalHours.toString(),
        subtitle: 'Hours Contributed',
        icon: Icons.access_time_rounded,
        color: const Color(0xFF5B34E6),
        extra: null,
      ),
      (
        title: 'Rating',
        value: _isLoadingRequests ? '-' : ratingStr,
        subtitle: '',
        icon: Icons.star_rounded,
        color: const Color(0xFF188A56),
        extra: Row(
          children: List.generate(5, (index) {
            return Icon(
              index < ratingVal.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 14,
              color: const Color(0xFFFDB528),
            );
          }),
        ),
      ),
      (
        title: 'Requests Completed',
        value: _isLoadingRequests ? '-' : completedRequests.toString(),
        subtitle: 'This Month',
        icon: Icons.shield_outlined,
        color: const Color(0xFF2166D8),
        extra: null,
      ),
      (
        title: 'Community Impact',
        value: _isLoadingRequests ? '-' : communityImpact.toString(),
        subtitle: 'People Helped',
        icon: Icons.groups_2_outlined,
        color: const Color(0xFFEF7B1A),
        extra: null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // In the wide layout (flex 2), we have more space.
        // If we have enough width, show 4 cards per row, otherwise 2.
        final bool showFour = constraints.maxWidth > 800;
        final cardWidth = showFour 
            ? (constraints.maxWidth - (3 * 12)) / 4
            : (constraints.maxWidth - 12) / 2;
        
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: item.color, size: 22),
                      ),
                      const SizedBox(height: 12),
                      Text(item.title,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        item.value,
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                      if (item.extra != null) item.extra!,
                      if (item.subtitle.isNotEmpty)
                        Text(item.subtitle,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _connectWithPeopleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_search_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Connect with People',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_searchResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final person = _searchResults[index];
                  final name = person['name'] ?? 'User';
                  final role = person['role'] ?? 'user';
                  final occupation = person['occupation'] ?? (role == 'volunteer' ? 'Volunteer' : 'Member');
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

                  final currentUserId = context.read<AuthService>().currentUser?.id;
                  final isFollowing = (person['followers'] as List?)?.contains(currentUserId) ?? false;
                  final isRequested = (person['followRequests'] as List?)?.contains(currentUserId) ?? false;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(initial, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(occupation, style: const TextStyle(fontSize: 12)),
                    trailing: ElevatedButton(
                      onPressed: (isFollowing || isRequested) ? null : () => _sendFollowRequest(person['_id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isFollowing || isRequested) ? Colors.grey.shade100 : AppColors.primary.withOpacity(0.1),
                        foregroundColor: (isFollowing || isRequested) ? Colors.grey : AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        isFollowing ? 'Connected' : (isRequested ? 'Requested' : 'Connect'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    onTap: () {
                      if (role == 'volunteer') {
                        NavHelper.push(context, VolunteerProfileScreen(volunteerId: person['_id']));
                      } else {
                        NavHelper.push(context, PublicProfileScreen(userId: person['_id']));
                      }
                    },
                  );
                },
              ),
            )
          else if (_searchController.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No users found.', style: TextStyle(color: AppColors.textMuted))),
            ),
        ],
      ),
    );
  }

  Widget _followRequestsCard() {
    if (_isLoadingFollowRequests) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pending Follow Requests (${_followRequests.length})',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_followRequests.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No pending follow requests at the moment.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
            )
          else
            ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _followRequests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final req = _followRequests[index];
              final name = req['name'] ?? 'User';
              final occupation = req['occupation'] ?? 'Member';
              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(initial, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(occupation, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _respondToFollowRequest(req['_id'], 'reject'),
                          icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                          tooltip: 'Reject',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.05),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _respondToFollowRequest(req['_id'], 'accept'),
                          icon: const Icon(Icons.check_rounded, color: Colors.green, size: 20),
                          tooltip: 'Accept',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green.withOpacity(0.05),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _skillsCard(AppUser? user) {
    List<String> skills = [];
    if (user != null) {
      if (user.skills != null && user.skills!.isNotEmpty) {
        skills.add(user.skills!);
      }
      if (user.areasOfHelp != null && user.areasOfHelp!.isNotEmpty) {
        skills.add(user.areasOfHelp!);
      }
      skills.addAll(user.languagesKnown);
    }

    if (skills.isEmpty) {
      skills = ['No skills added yet'];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Skills',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              InkWell(
                onTap: () => NavHelper.replaceWith(context, const ProfileScreen()),
                child: const Text(
                  'Manage Skills',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: skills
                .map(
                  (skill) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EEFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _experienceCard(AppUser? user) {
    final years = user?.yearsOfExperience?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '0';
    final desc = (user?.volunteerExperience?.isNotEmpty == true)
        ? user!.volunteerExperience!
        : 'Update your profile to showcase your experience and background.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2EEFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  years.isEmpty ? '0' : years,
                  style: const TextStyle(
                    fontSize: 30,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text('Years'),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              InkWell(
                onTap: () => NavHelper.push(
                  context,
                  const HelpRequestsScreen(
                    isVolunteer: true,
                    statusFilter: 'all',
                    title: 'All Requests',
                  ),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoadingRequests)
            const Center(child: CircularProgressIndicator())
          else if (_requests.isEmpty)
            const Text('No recent activity', style: TextStyle(color: AppColors.textMuted, fontSize: 13))
          else
            ..._requests.take(3).map((req) {
              final status = req['status'] as String? ?? 'unknown';
              IconData icon = Icons.edit_note_rounded;
              String title = 'Request Update';
              String subtitle = req['message']?.toString() ?? 'No details';
              
              if (status == 'completed') {
                icon = Icons.task_alt_rounded;
                title = 'Completed a request';
                subtitle = 'Helped ${req['requesterId']?['name'] ?? "User"}';
              } else if (status == 'pending') {
                icon = Icons.notification_important_rounded;
                title = 'New help request';
                subtitle = 'From ${req['requesterId']?['name'] ?? "User"}';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2EEFF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(
                            subtitle,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Text('Just now', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
  Widget _knowCommunityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Know Your Community',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary),
                ),
                const Text(
                  'Explore recent blogs, safety articles, and community stories.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => NavHelper.push(context, const KnowCommunityScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Explore'),
          ),
        ],
      ),
    );
  }
}
