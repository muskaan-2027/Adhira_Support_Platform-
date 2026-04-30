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
import 'profile_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _loading = true;
  AppUser? _user;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;
  bool _isRequested = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;
      
      final userResponse = await ApiService.getUserById(token, widget.userId);
      final followInfo = await ApiService.getFollowInfo(token, widget.userId);
      
      if (!mounted) return;
      setState(() {
        _user = AppUser.fromJson(userResponse['user']);
        _followersCount = (followInfo['followers'] as num?)?.toInt() ?? 0;
        _followingCount = (followInfo['following'] as num?)?.toInt() ?? 0;
        _isFollowing = followInfo['isFollowing'] as bool? ?? false;
        _isRequested = followInfo['isRequested'] as bool? ?? false;
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
      final result = await ApiService.followVolunteer(token, widget.userId);
      
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
    final isSelf = currentUser?.id == widget.userId;

    return UserShellLayout(
      selectedSection: UserNavSection.community,
      title: _user?.role == 'volunteer' ? 'Volunteer Profile' : 'User Profile',
      subtitle: _user?.name ?? 'Loading...',
      userName: currentUser?.name ?? 'User',
      accountRole: currentUser?.role ?? 'User',
      statusText: 'Verified',
      onProfileTap: () => NavHelper.replaceWith(context, const ProfileScreen()),
      onLogout: () => auth.logout(),
      onBackTap: () => Navigator.of(context).pop(),
      navItems: NavHelper.getNavItems(context, currentUser),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildHeaderCard(isSelf),
                  const SizedBox(height: 24),
                  _buildDetailsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(bool isSelf) {
    final initial = _user?.name.isNotEmpty == true ? _user!.name[0].toUpperCase() : 'U';
    
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: _user?.profilePhoto != null && _user!.profilePhoto!.isNotEmpty
                ? MemoryImage(base64Decode(_user!.profilePhoto!))
                : null,
            child: _user?.profilePhoto == null || _user!.profilePhoto!.isEmpty
                ? Text(initial, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary))
                : null,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_user?.name ?? 'User', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text(_user?.occupation ?? (_user?.role == 'volunteer' ? 'Volunteer' : 'Member'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _socialStat('Followers', _followersCount),
                    const SizedBox(width: 24),
                    _socialStat('Following', _followingCount),
                  ],
                ),
                const SizedBox(height: 12),
                _statusChip(_user?.volunteerAvailability == 'active'),
              ],
            ),
          ),
          if (!isSelf)
            ElevatedButton(
              onPressed: _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: textColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(bool isActive) {
    return Container(
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

  Widget _buildDetailsSection() {
    final hasAbout = _user?.volunteerExperience?.isNotEmpty == true || _user?.additionalInfo?.isNotEmpty == true;
    final hasSkills = _user?.skills?.isNotEmpty == true;
    final hasExperience = _user?.yearsOfExperience?.isNotEmpty == true || _user?.occupation?.isNotEmpty == true;
    final languages = _user?.languagesKnown ?? [];

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _detailItem(Icons.location_on_outlined, 'Location', '${_user?.city ?? 'Not shared'}, ${_user?.state ?? ''}'),
              ),
              Expanded(
                child: _detailItem(Icons.work_outline, 'Occupation', 
                  (_user?.occupation?.isNotEmpty == true) ? _user!.occupation! : 'Member'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('About Yourself', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            (_user?.volunteerExperience?.isNotEmpty == true) 
                ? _user!.volunteerExperience! 
                : (_user?.additionalInfo?.isNotEmpty == true) 
                    ? _user!.additionalInfo! 
                    : 'No description shared.',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 24),
          
          if (hasExperience) ...[
            _detailItem(Icons.history_edu_outlined, 'Experience', '${_user?.yearsOfExperience ?? '0'} years of experience'),
            const SizedBox(height: 24),
          ],

          if (languages.isNotEmpty) ...[
            const Text('Languages', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: languages.map((l) => Chip(
                label: Text(l),
                backgroundColor: const Color(0xFFF2EEFF),
                labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                side: BorderSide.none,
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],

          if (hasSkills) ...[
            const Text('Skills & Expertise', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_user?.skills?.split(',') ?? []).map((s) => Chip(
                label: Text(s.trim()),
                backgroundColor: const Color(0xFFE8F7EF),
                labelStyle: const TextStyle(color: Color(0xFF188A56), fontWeight: FontWeight.w500),
                side: BorderSide.none,
              )).toList(),
            ),
          ],
          
          if (!hasAbout && !hasSkills && !hasExperience && languages.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No additional details shared.', style: TextStyle(color: AppColors.textMuted)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
