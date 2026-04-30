import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/user_shell_layout.dart';
import '../utils/nav_helper.dart';
import 'profile_screen.dart';
import 'sos_screen.dart';
import 'user_dashboard_screen.dart';
import 'volunteer_dashboard_screen.dart';

class ProfileDashboardScreen extends StatefulWidget {
  const ProfileDashboardScreen({super.key});

  @override
  State<ProfileDashboardScreen> createState() => _ProfileDashboardScreenState();
}

class _ProfileDashboardScreenState extends State<ProfileDashboardScreen> {
  bool _loading = true;
  int _followersCount = 0;
  int _followingCount = 0;
  List<dynamic> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final auth = context.read<AuthService>();
      await auth.refreshProfile();
      final token = auth.token;
      final userId = auth.currentUser?.id;
      if (token == null || userId == null) return;

      final info = await ApiService.getFollowInfo(token, userId);
      final sosHistory = await ApiService.getSOSHistory(token);
      final helpRequests = await ApiService.getHelpRequests(token);

      if (!mounted) return;
      setState(() {
        _followersCount = (info['followers'] as num?)?.toInt() ?? 0;
        _followingCount = (info['following'] as num?)?.toInt() ?? 0;
        
        _recentActivity = [
          ...(sosHistory['history'] as List<dynamic>? ?? []).map((e) => {
            'type': 'sos',
            'title': 'Emergency SOS Alert',
            'subtitle': 'Location alert sent to contacts',
            'date': e['createdAt'],
            'icon': Icons.warning_amber_rounded,
            'color': Colors.red,
          }),
          ...(helpRequests['requests'] as List<dynamic>? ?? []).map((e) => {
            'type': 'help',
            'title': e['status'] == 'completed' ? 'Help Request Completed' : 'Help Request Created',
            'subtitle': e['message'] ?? 'Need guidance',
            'date': e['updatedAt'] ?? e['createdAt'],
            'icon': e['status'] == 'completed' ? Icons.check_circle_rounded : Icons.support_agent_rounded,
            'color': e['status'] == 'completed' ? Colors.green : AppColors.primary,
          }),
        ];
        
        _recentActivity.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
        _recentActivity = _recentActivity.take(5).toList();

        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final userName = user?.name ?? 'User';

    return UserShellLayout(
      selectedSection: UserNavSection.profile,
      title: 'My Profile',
      subtitle: 'Manage your personal information and account settings.',
      userName: userName,
      accountRole: user?.role == 'volunteer' ? 'Volunteer' : 'User',
      statusText: 'Active',
      onProfileTap: () => NavHelper.replaceWith(context, const ProfileScreen()),
      onLogout: () => auth.logout(),
      onBackTap: () {
        if (user?.role == 'volunteer') {
          NavHelper.replaceWith(context, VolunteerDashboardScreen());
        } else {
          NavHelper.replaceWith(context, UserDashboardScreen());
        }
      },
      navItems: NavHelper.getNavItems(context, user),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(user),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isWide = constraints.maxWidth > 900;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildPersonalInfo(user)),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    _buildSecurityInfo(user),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildPersonalInfo(user),
                              const SizedBox(height: 24),
                              _buildSecurityInfo(user),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard(AppUser? user) {
    final memberSince = user?.createdAt != null 
        ? DateFormat('dd MMM yyyy').format(user!.createdAt!)
        : '29 Apr 2026';
    final initial = user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty
                    ? MemoryImage(base64Decode(user.profilePhoto!))
                    : null,
                child: user?.profilePhoto == null || user!.profilePhoto!.isEmpty
                    ? Text(initial, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary))
                    : null,
              ),
              Positioned(
                bottom: 0,
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                    child: const Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'User', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user?.email ?? 'user@example.com', style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
                const SizedBox(height: 4),
                Text(user?.phone ?? '+91 98765 43210', style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          _headerStat(Icons.calendar_today_outlined, 'Member Since', memberSince),
          const SizedBox(width: 32),
          Column(
            children: [
              _socialStat(Icons.groups_outlined, 'Followers', _followersCount),
              const SizedBox(height: 16),
              _socialStat(Icons.person_add_outlined, 'Following', _followingCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(IconData icon, String label, String value, {bool isStatus = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFE8F7EF), borderRadius: BorderRadius.circular(8)),
              child: const Text('Active', style: TextStyle(color: Color(0xFF188A56), fontWeight: FontWeight.bold, fontSize: 12)),
            )
          else
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _socialStat(IconData icon, String label, int value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInfo(AppUser? user) {
    return _infoSection(
      icon: Icons.person_outline_rounded,
      title: 'Personal Information',
      children: [
        _infoRow('Full Name', user?.name ?? 'User'),
        _infoRow('Email Address', user?.email ?? 'user@example.com'),
        _infoRow('Phone Number', user?.phone ?? '+91 98765 43210'),
        _infoRow('Date of Birth', user?.dateOfBirth ?? '12 Jan 2000'),
        _infoRow('Gender', user?.gender ?? 'Female'),
        _infoRow('Location', '${user?.city ?? 'Not shared'}, ${user?.state ?? ''}'),
        _infoRow('Occupation', (user?.occupation?.isNotEmpty == true) ? user!.occupation! : 'Not shared'),
        _infoRow('About Myself', (user?.volunteerExperience?.isNotEmpty == true) ? user!.volunteerExperience! : 'No description shared'),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Update Personal Information', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityInfo(AppUser? user) {
    return _infoSection(
      icon: Icons.shield_outlined,
      title: 'Security',
      children: [
        _navInfoRow('Password', '*********', onTap: () {
          _showChangePasswordDialog(context);
        }),
        _navInfoRow('Emergency Contacts', '${user?.emergencyContacts.length ?? 0} Contacts', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SOSScreen()));
        }),
      ],
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool loading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Old Password'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: loading ? null : () async {
                  if (oldPasswordController.text.isEmpty || newPasswordController.text.isEmpty) {
                    NotificationService.showMessage(context, 'Both fields are required');
                    return;
                  }
                  setState(() => loading = true);
                  try {
                    final token = context.read<AuthService>().token;
                    if (token != null) {
                      await ApiService.changePassword(token, oldPasswordController.text, newPasswordController.text);
                      if (context.mounted) {
                        Navigator.pop(context);
                        NotificationService.showMessage(context, 'Password changed successfully');
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      NotificationService.showMessage(context, e.toString().replaceFirst('Exception: ', ''));
                    }
                  } finally {
                    setState(() => loading = false);
                  }
                },
                child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Change'),
              ),
            ],
          );
        },
      ),
    );
  }



  Widget _infoSection({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _navInfoRow(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            Row(
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 12),
                  Text('Recent Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentActivity.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No recent activity found.', style: TextStyle(color: AppColors.textMuted))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentActivity.length,
              separatorBuilder: (context, index) => Divider(color: AppColors.border.withOpacity(0.5)),
              itemBuilder: (context, index) {
                final activity = _recentActivity[index];
                final date = DateTime.parse(activity['date']);
                final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: activity['color'].withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(activity['icon'], color: activity['color'], size: 22),
                  ),
                  title: Text(activity['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(activity['subtitle'], style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  trailing: Text(formattedDate, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                );
              },
            ),
        ],
      ),
    );
  }
}


