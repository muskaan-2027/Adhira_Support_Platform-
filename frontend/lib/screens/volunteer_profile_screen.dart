import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/nav_helper.dart';
import '../widgets/user_shell_layout.dart';
import 'profile_screen.dart';

class VolunteerProfileScreen extends StatefulWidget {
  final String volunteerId;
  const VolunteerProfileScreen({super.key, required this.volunteerId});

  @override
  State<VolunteerProfileScreen> createState() => _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen> {
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;
  bool _isRequested = false;
  bool _loading = true;
  AppUser? _volunteer;

  // New stats
  int _totalHours = 0;
  int _communityImpact = 0;
  int _completedRequests = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;
      
      // Load full user details
      final userResponse = await ApiService.getUserById(token, widget.volunteerId);
      final followInfo = await ApiService.getFollowInfo(token, widget.volunteerId);
      final workResponse = await ApiService.getVolunteerWork(token, widget.volunteerId);
      
      if (!mounted) return;

      // Calculate work stats
      final workList = workResponse['requests'] as List<dynamic>? ?? [];
      int hours = 0;
      int impact = 0;
      for (var r in workList) {
        hours += (r['hoursSpent'] as num?)?.toInt() ?? 0;
        impact += (r['peopleHelped'] as num?)?.toInt() ?? 0;
      }

      setState(() {
        _volunteer = AppUser.fromJson(userResponse['user']);
        _followersCount = (followInfo['followers'] as num?)?.toInt() ?? 0;
        _followingCount = (followInfo['following'] as num?)?.toInt() ?? 0;
        _isFollowing = followInfo['isFollowing'] as bool? ?? false;
        _isRequested = followInfo['isRequested'] as bool? ?? false;
        
        _totalHours = hours;
        _communityImpact = impact;
        _completedRequests = workList.length;

        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        NotificationService.showMessage(context, e.toString());
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;
      final result = await ApiService.followVolunteer(token, widget.volunteerId);
      
      if (!mounted) return;
      setState(() {
        _isFollowing = result['isFollowing'] ?? false;
        _isRequested = result['isRequested'] ?? false;
        _followersCount = (result['followers'] as num?)?.toInt() ?? _followersCount;
      });
      NotificationService.showMessage(context, result['message'] ?? 'Status updated');
    } catch (e) {
      NotificationService.showMessage(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final currentUser = auth.currentUser;
    
    // Determine if we are viewing ourselves
    final bool isSelf = currentUser?.id == widget.volunteerId;

    return UserShellLayout(
      selectedSection: UserNavSection.volunteers,
      title: isSelf ? 'My Public Profile' : 'Volunteer Profile',
      subtitle: _volunteer?.name ?? 'Loading...',
      userName: currentUser?.name ?? 'Volunteer',
      accountRole: currentUser?.role ?? 'User',
      statusText: 'Verified',
      onProfileTap: () => NavHelper.replaceWith(context, const ProfileScreen()),
      onLogout: () => context.read<AuthService>().logout(),
      navItems: NavHelper.getNavItems(context, currentUser),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    label: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _headerSection(),
                  const SizedBox(height: 24),
                  _statsRow(),
                  const SizedBox(height: 24),
                  _activityStatsRow(),
                  const SizedBox(height: 24),
                  _aboutSection(),
                  const SizedBox(height: 24),
                  _skillsSection(),
                  const SizedBox(height: 24),
                  _languagesSection(),
                  const SizedBox(height: 24),
                  if (!isSelf) _requestSupportSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  final TextEditingController _requestController = TextEditingController();
  bool _sendingRequest = false;

  Widget _requestSupportSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF9F8FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
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
                child: const Icon(Icons.handshake_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Support',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Tell this volunteer how they can help you',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _requestController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe your situation or the type of assistance you need...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _sendingRequest ? null : _sendHelpRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _sendingRequest
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Send Help Request',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendHelpRequest() async {
    final message = _requestController.text.trim();
    if (message.isEmpty) {
      NotificationService.showMessage(context, 'Please enter a message');
      return;
    }

    setState(() => _sendingRequest = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');
      
      await ApiService.createHelpRequest(token, message: message, volunteerId: widget.volunteerId);
      
      if (!mounted) return;
      _requestController.clear();
      NotificationService.showMessage(context, 'Help request sent to ${_volunteer?.name ?? "the volunteer"}');
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(context, err.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sendingRequest = false);
    }
  }

  Widget _headerSection() {
    final initial = _volunteer?.name.isNotEmpty == true ? _volunteer!.name[0].toUpperCase() : 'V';
    
    String buttonText = 'Follow';
    Color buttonColor = AppColors.primary;
    Color textColor = Colors.white;

    if (_isFollowing) {
      buttonText = 'Unfollow';
      buttonColor = Colors.grey[100]!;
      textColor = Colors.black87;
    } else if (_isRequested) {
      buttonText = 'Requested';
      buttonColor = AppColors.primary.withOpacity(0.1);
      textColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: _volunteer?.profilePhoto != null && _volunteer!.profilePhoto!.isNotEmpty
                ? MemoryImage(base64Decode(_volunteer!.profilePhoto!))
                : null,
            child: _volunteer?.profilePhoto == null || _volunteer!.profilePhoto!.isEmpty
                ? Text(initial, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary))
                : null,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_volunteer?.name?.isNotEmpty == true ? _volunteer!.name : 'Volunteer', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text(_volunteer?.occupation?.isNotEmpty == true ? _volunteer!.occupation! : 'Volunteer', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(_getLocation(), style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _socialStat('Followers', _followersCount),
                    const SizedBox(width: 24),
                    _socialStat('Following', _followingCount),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              ElevatedButton(
                onPressed: _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: textColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: _isFollowing || _isRequested ? BorderSide(color: AppColors.border) : null,
                ),
                child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => NotificationService.showMessage(context, 'Chat coming soon'),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Chat'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialStat(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ],
    );
  }

  Widget _statsRow() {
    final rating = _volunteer != null ? _volunteer!.averageRating.toStringAsFixed(1) : '0.0';
    final experience = _volunteer?.yearsOfExperience?.isNotEmpty == true ? _volunteer!.yearsOfExperience! : '0';
    final status = _volunteer?.volunteerAvailability?.toUpperCase() ?? 'ACTIVE';

    return Row(
      children: [
        _miniStatCard('Rating', rating, Icons.star_rounded, const Color(0xFFFDB528)),
        const SizedBox(width: 16),
        _miniStatCard('Experience', '$experience Yrs', Icons.workspace_premium_rounded, AppColors.primary),
        const SizedBox(width: 16),
        _miniStatCard('Status', status, Icons.circle, const Color(0xFF188A56)),
      ],
    );
  }

  Widget _activityStatsRow() {
    return Row(
      children: [
        _miniStatCard('Hours Spent', _totalHours.toString(), Icons.access_time_filled_rounded, Colors.blue),
        const SizedBox(width: 16),
        _miniStatCard('Impact', _communityImpact.toString(), Icons.groups_rounded, Colors.orange),
        const SizedBox(width: 16),
        _miniStatCard('Completed', _completedRequests.toString(), Icons.verified_rounded, Colors.teal),
      ],
    );
  }

  Widget _miniStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _aboutSection() {
    final bio = _volunteer?.volunteerExperience?.isNotEmpty == true 
        ? _volunteer!.volunteerExperience! 
        : 'This volunteer hasn\'t shared their experience yet.';

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
          const Text('About Volunteer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            bio,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _skillsSection() {
    var skills = (_volunteer?.skills?.split(',') ?? []).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
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
          const Text('Skills & Expertise', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (skills.isEmpty)
            const Text('No skills listed', style: TextStyle(color: AppColors.textMuted))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: skills.map((skill) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(skill, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
        ],
      ),
    );
  }

  String _getLocation() {
    final city = _volunteer?.city ?? '';
    final state = _volunteer?.state ?? '';
    if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
    if (city.isNotEmpty) return city;
    if (state.isNotEmpty) return state;
    return 'India';
  }

  Widget _languagesSection() {
    var languages = _volunteer?.languagesKnown ?? [];
    
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
          const Text('Languages', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (languages.isEmpty)
            const Text('No languages listed', style: TextStyle(color: AppColors.textMuted))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: languages.map((lang) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(lang, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
        ],
      ),
    );
  }
}
