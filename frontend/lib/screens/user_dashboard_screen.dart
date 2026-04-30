import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/user_shell_layout.dart';
import 'chatbot_screen.dart';
import 'community_screen.dart';
import 'know_community_screen.dart';
import 'need_guidance_screen.dart';
import 'profile_screen.dart';
import 'profile_dashboard_screen.dart';
import 'sos_screen.dart';
import 'volunteer_profiles_screen.dart';
import 'public_profile_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  List<dynamic> _followRequests = [];
  bool _isLoadingFollowRequests = true;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchFollowRequests();
    _loadFollowInfo();
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
      });
    } catch (e) {
      // ignore
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

  void _replaceWith(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  List<UserNavItem> _navItems(BuildContext context) {
    return [
      UserNavItem(
        label: 'Dashboard',
        icon: Icons.home_outlined,
        section: UserNavSection.dashboard,
        onTap: () {},
      ),
      UserNavItem(
        label: 'Emergency SOS',
        icon: Icons.warning_amber_rounded,
        section: UserNavSection.sos,
        onTap: () => _replaceWith(context, const SOSScreen()),
      ),
      UserNavItem(
        label: 'Need Guidance',
        icon: Icons.support_agent_rounded,
        section: UserNavSection.needGuidance,
        onTap: () => _replaceWith(context, const NeedGuidanceScreen()),
      ),
      UserNavItem(
        label: 'Volunteer Profiles',
        icon: Icons.groups_2_outlined,
        section: UserNavSection.volunteers,
        onTap: () => _replaceWith(context, const VolunteerProfilesScreen()),
      ),
      UserNavItem(
        label: 'Community',
        icon: Icons.forum_outlined,
        section: UserNavSection.community,
        onTap: () => _replaceWith(context, const CommunityScreen()),
      ),
      UserNavItem(
        label: 'Chatbot Assistant',
        icon: Icons.chat_bubble_outline_rounded,
        section: UserNavSection.chatbot,
        onTap: () => _replaceWith(context, const ChatbotScreen()),
      ),
      UserNavItem(
        label: 'Know Your Community',
        icon: Icons.people_outline_rounded,
        section: UserNavSection.knowCommunity,
        onTap: () => _replaceWith(context, const KnowCommunityScreen()),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final userName = user?.name ?? 'User';

    return UserShellLayout(
      selectedSection: UserNavSection.dashboard,
      title: 'Welcome back, ${userName.toLowerCase()}!',
      subtitle: 'Stay safe, stay strong.',
      userName: userName,
      supportIcon: Icons.health_and_safety_rounded,
      onProfileTap: () => _replaceWith(context, const ProfileScreen()),
      onLogout: () => context.read<AuthService>().logout(),
      statusText: user?.volunteerAvailability == 'active' ? 'Active' : 'Stay Safe',
      navItems: _navItems(context),
      child: Column(
        children: [
          _greeting(userName, user),
          _profileCard(user),
          const SizedBox(height: 16),
          _followRequestsCard(),
          const SizedBox(height: 16),
          _availabilitySection(user),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1050 ? 3 : 2;
              final cardWidth =
                  (constraints.maxWidth - (columns - 1) * 16) / columns;
              final cardHeight = constraints.maxWidth >= 1050 ? 300.0 : 280.0;

              final cards = [
                _DashboardFeatureCard(
                  title: 'Emergency SOS',
                  subtitle:
                      'In an emergency? Send an alert to your trusted contacts instantly.',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFDC284C),
                  iconBg: const Color(0xFFFFE8EE),
                  buttonLabel: 'Send SOS',
                  buttonBg: const Color(0xFFFFE9EE),
                  buttonColor: const Color(0xFFDC284C),
                  onTap: () => _replaceWith(context, const SOSScreen()),
                ),
                _DashboardFeatureCard(
                  title: 'Need Guidance',
                  subtitle:
                      'Get support and guidance from experts and trained professionals.',
                  icon: Icons.support_agent_rounded,
                  color: AppColors.primary,
                  iconBg: const Color(0xFFEDE7FF),
                  buttonLabel: 'Get Guidance',
                  buttonBg: const Color(0xFFF2EEFF),
                  buttonColor: AppColors.primary,
                  onTap: () =>
                      _replaceWith(context, const NeedGuidanceScreen()),
                ),
                _DashboardFeatureCard(
                  title: 'Volunteer Profiles',
                  subtitle:
                      'View verified volunteers who can help and assist you.',
                  icon: Icons.groups_2_rounded,
                  color: const Color(0xFF188A56),
                  iconBg: const Color(0xFFE8F7EF),
                  buttonLabel: 'View Volunteers',
                  buttonBg: const Color(0xFFEBF9F1),
                  buttonColor: const Color(0xFF188A56),
                  onTap: () =>
                      _replaceWith(context, const VolunteerProfilesScreen()),
                ),
                _DashboardFeatureCard(
                  title: 'Community',
                  subtitle:
                      'Join the community, share, support and empower each other.',
                  icon: Icons.forum_outlined,
                  color: const Color(0xFFEF7B1A),
                  iconBg: const Color(0xFFFFF2E8),
                  buttonLabel: 'Explore Community',
                  buttonBg: const Color(0xFFFFF3E9),
                  buttonColor: const Color(0xFFEF7B1A),
                  onTap: () => _replaceWith(context, const CommunityScreen()),
                ),
                _DashboardFeatureCard(
                  title: 'Chatbot Assistant',
                  subtitle:
                      'Chat with our AI assistant anytime for quick help and information.',
                  icon: Icons.smart_toy_outlined,
                  color: const Color(0xFF2166D8),
                  iconBg: const Color(0xFFEAF2FF),
                  buttonLabel: 'Chat Now',
                  buttonBg: const Color(0xFFEDF4FF),
                  buttonColor: const Color(0xFF2166D8),
                  onTap: () => _replaceWith(context, const ChatbotScreen()),
                ),
                _DashboardFeatureCard(
                  title: 'Know Your Community',
                  subtitle:
                      'Find support, share experiences, and stay informed.',
                  icon: Icons.people_outline_rounded,
                  color: AppColors.primary,
                  iconBg: const Color(0xFFEDE7FF),
                  buttonLabel: 'Explore Now',
                  buttonBg: const Color(0xFFF2EEFF),
                  buttonColor: AppColors.primary,
                  onTap: () => _replaceWith(context, const KnowCommunityScreen()),
                ),
              ];

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: card,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          _safetyBanner(),
        ],
      ),
    );
  }

  Widget _profileCard(AppUser? user) {
    final initial = user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U';
    
    ImageProvider? profileImage;
    if (user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty) {
      try {
        final String base64String = user.profilePhoto!.contains(',') 
            ? user.profilePhoto!.split(',').last 
            : user.profilePhoto!;
        profileImage = MemoryImage(base64Decode(base64String));
      } catch (e) {
        debugPrint('Failed to decode profile photo: $e');
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: profileImage,
                child: profileImage == null
                    ? Text(initial, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary))
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(user?.email ?? 'user@example.com', style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _socialStat('Followers', _followersCount),
                        const SizedBox(width: 24),
                        _socialStat('Following', _followingCount),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _availabilityToggle(user),
                  ],
                ),
              ),
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _replaceWith(context, const ProfileDashboardScreen()),
                    icon: const Icon(Icons.account_circle_outlined, size: 16),
                    label: const Text('View Full Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9F5FF),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (user?.id != null) {
                        _replaceWith(context, PublicProfileScreen(userId: user!.id));
                      }
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View Public'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (user?.skills != null || user?.volunteerExperience != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user?.volunteerExperience != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          user!.volunteerExperience!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (user?.skills != null) ...[
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: user!.skills!
                              .split(',')
                              .take(3)
                              .map((s) => Chip(
                                    label: Text(s.trim(), style: const TextStyle(fontSize: 10)),
                                    padding: EdgeInsets.zero,
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _greeting(String userName, AppUser? user) {
    final isActive = user?.volunteerAvailability == 'active';
    return Column(
      children: [
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF188A56) : const Color(0xFFDC284C),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isActive ? 'You are currently Active' : 'You are currently Inactive',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isActive ? const Color(0xFF188A56) : const Color(0xFFDC284C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _availabilityToggle(AppUser? user) {
    final isActive = user?.volunteerAvailability == 'active';
    return InkWell(
      onTap: () async {
        try {
          final newStatus = isActive ? 'inactive' : 'active';
          await context.read<AuthService>().updateVolunteerAvailability(newStatus);
          if (mounted) {
            NotificationService.showMessage(context, 'Status updated to ${newStatus.toUpperCase()}');
          }
        } catch (e) {
          if (mounted) NotificationService.showMessage(context, e.toString());
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEAF8F0) : const Color(0xFFFFE9EE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFF188A56).withOpacity(0.2) : const Color(0xFFDC284C).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: isActive ? const Color(0xFF188A56) : const Color(0xFFDC284C)),
            const SizedBox(width: 6),
            Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF188A56) : const Color(0xFFDC284C),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.sync_rounded, size: 12, color: isActive ? const Color(0xFF188A56) : const Color(0xFFDC284C)),
          ],
        ),
      ),
    );
  }

  Widget _availabilitySection(AppUser? user) {
    final isActive = user?.volunteerAvailability == 'active';
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFEAF8F0) : const Color(0xFFFFE9EE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.verified_user_rounded : Icons.person_off_rounded,
              color: isActive ? const Color(0xFF188A56) : const Color(0xFFDC284C),
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Availability Status',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                Text(
                  isActive 
                    ? 'You are currently visible to volunteers and the community.' 
                    : 'You are currently hidden. Toggle to become active.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Switch.adaptive(
            value: isActive,
            activeColor: const Color(0xFF188A56),
            onChanged: (val) async {
              try {
                final newStatus = val ? 'active' : 'inactive';
                await context.read<AuthService>().updateVolunteerAvailability(newStatus);
                if (mounted) {
                  NotificationService.showMessage(context, 'Status updated to ${newStatus.toUpperCase()}');
                }
              } catch (e) {
                if (mounted) NotificationService.showMessage(context, e.toString());
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _socialStat(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _followRequestsCard() {
    if (_isLoadingFollowRequests) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connection Requests',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Volunteers who want to support you',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              const Spacer(),
              if (_followRequests.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_followRequests.length} New',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_followRequests.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text(
                    'No pending requests at the moment.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _followRequests.length,
              separatorBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFF0F0F0)),
              ),
              itemBuilder: (context, index) {
                final req = _followRequests[index];
                final name = req['name'] ?? 'Volunteer';
                final occupation = req['occupation'] ?? 'Community Helper';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : 'V';

                return Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.1)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                          ),
                          Text(
                            occupation,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _actionButton(
                          onTap: () => _respondToFollowRequest(req['_id'], 'reject'),
                          icon: Icons.close_rounded,
                          color: const Color(0xFFDC284C),
                          label: 'Reject',
                        ),
                        const SizedBox(width: 8),
                        _actionButton(
                          onTap: () => _respondToFollowRequest(req['_id'], 'accept'),
                          icon: Icons.check_rounded,
                          color: const Color(0xFF188A56),
                          label: 'Accept',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _actionButton({required VoidCallback onTap, required IconData icon, required Color color, required String label}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _safetyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFF2EBFF), Color(0xFFEDE7FF)],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_rounded, color: AppColors.primary, size: 42),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your safety is our priority.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Report, connect and get help - because every woman matters.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.favorite_rounded, color: AppColors.primary, size: 44),
        ],
      ),
    );
  }
}

class _DashboardFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color iconBg;
  final String buttonLabel;
  final Color buttonBg;
  final Color buttonColor;
  final VoidCallback onTap;

  const _DashboardFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconBg,
    required this.buttonLabel,
    required this.buttonBg,
    required this.buttonColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: buttonColor,
              side: BorderSide(color: buttonColor.withOpacity(0.35)),
              backgroundColor: buttonBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onPressed: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
