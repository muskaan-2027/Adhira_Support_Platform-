import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/volunteer_profile_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/user_shell_layout.dart';
import '../utils/nav_helper.dart';
import 'chatbot_screen.dart';
import 'help_requests_screen.dart';
import 'profile_screen.dart';
import 'volunteer_profiles_screen.dart';

class NeedGuidanceScreen extends StatefulWidget {
  const NeedGuidanceScreen({super.key});

  @override
  State<NeedGuidanceScreen> createState() => _NeedGuidanceScreenState();
}

class _NeedGuidanceScreenState extends State<NeedGuidanceScreen> {
  bool _loadingVolunteers = false;
  List<VolunteerProfileModel> _volunteers = [];

  Future<void> _fetchVolunteers() async {
    setState(() => _loadingVolunteers = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');
      final response = await ApiService.getVolunteerProfiles(token, onlyActive: false);
      final list = response['volunteers'] as List<dynamic>? ?? [];
      _volunteers = list
          .whereType<Map<String, dynamic>>()
          .map(VolunteerProfileModel.fromJson)
          .toList();
    } catch (err) {
      debugPrint('Error fetching volunteers: $err');
    } finally {
      if (mounted) setState(() => _loadingVolunteers = false);
    }
  }

  Future<void> _requestVolunteerHelp(BuildContext context) async {
    await _fetchVolunteers();

    if (!context.mounted) return;

    // Sort volunteers by rating (desc) and experience (desc)
    _volunteers.sort((a, b) {
      final ratingCompare = b.averageRating.compareTo(a.averageRating);
      if (ratingCompare != 0) return ratingCompare;
      final expA = int.tryParse(a.yearsOfExperience.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final expB = int.tryParse(b.yearsOfExperience.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return expB.compareTo(expA);
    });

    final controller = TextEditingController();
    String? selectedVolunteerId;
    String searchQuery = '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredVolunteers = _volunteers.where((v) {
              final q = searchQuery.toLowerCase();
              return v.name.toLowerCase().contains(q) || v.areasOfHelp.toLowerCase().contains(q);
            }).toList();

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Request Help',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Text(
                        'Select a verified volunteer to assist you with your specific needs.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          onChanged: (val) => setDialogState(() => searchQuery = val),
                          decoration: const InputDecoration(
                            hintText: 'Search by name or expertise...',
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Volunteer List
                      Container(
                        height: 200, // Reduced height slightly to fit better
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.builder(
                            itemCount: filteredVolunteers.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                final isSelected = selectedVolunteerId == '';
                                return InkWell(
                                  onTap: () => setDialogState(() => selectedVolunteerId = ''),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                                      border: Border(bottom: BorderSide(color: const Color(0xFFE5E7EB))),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                                          radius: 20,
                                          child: Icon(Icons.groups_rounded, color: isSelected ? Colors.white : AppColors.textMuted, size: 20),
                                        ),
                                        const SizedBox(width: 16),
                                        const Text('Any Available Volunteer', style: TextStyle(fontWeight: FontWeight.w700)),
                                        const Spacer(),
                                        if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              final v = filteredVolunteers[index - 1];
                              final isSelected = selectedVolunteerId == v.id;
                              return InkWell(
                                onTap: () => setDialogState(() => selectedVolunteerId = v.id),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                                    border: Border(bottom: BorderSide(color: const Color(0xFFE5E7EB))),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isSelected ? AppColors.primary : const Color(0xFFE0E7FF),
                                        radius: 20,
                                        child: Text(v.name[0].toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : AppColors.primary, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(v.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                            Text(
                                              '${v.averageRating.toStringAsFixed(1)} ⭐ | ${v.areasOfHelp}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('How can we help you?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Describe your situation...',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFF),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (controller.text.trim().isEmpty) {
                              NotificationService.showMessage(context, 'Please enter a description');
                              return;
                            }
                            Navigator.pop(context, {
                              'message': controller.text.trim(),
                              'volunteerId': selectedVolunteerId ?? '',
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) return;
    if (!context.mounted) return;

    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');
      
      await ApiService.createHelpRequest(
        token,
        message: result['message']!,
        volunteerId: result['volunteerId']!.isEmpty ? null : result['volunteerId'],
      );
      
      if (!context.mounted) return;
      NotificationService.showMessage(
          context, 'Help request sent successfully!');
    } catch (err) {
      if (!context.mounted) return;
      NotificationService.showMessage(
        context,
        err.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final userName = user?.name ?? 'User';
    return UserShellLayout(
      selectedSection: UserNavSection.needGuidance,
      title: 'Need Guidance',
      subtitle: 'Choose a support type to get the help and guidance you need.',
      userName: userName,
      accountRole: user?.role == 'volunteer' ? 'Volunteer' : 'User',
      onProfileTap: () => NavHelper.replaceWith(context, const ProfileScreen()),
      onLogout: () => context.read<AuthService>().logout(),
      navItems: NavHelper.getNavItems(context, user),
      child: Column(
        children: [
          ShellActionCard(
            title: 'Open Chatbot',
            subtitle:
                'Chat with our AI assistant for quick help and information.',
            icon: Icons.support_agent_rounded,
            iconColor: const Color(0xFF5B34E6),
            iconBackground: const Color(0xFFEDE7FF),
            onTap: () => NavHelper.replaceWith(context, const ChatbotScreen()),
          ),
          ShellActionCard(
            title: 'Request Volunteer Help',
            subtitle: 'Request help from specific verified volunteers.',
            icon: Icons.volunteer_activism_rounded,
            iconColor: const Color(0xFFD9468B),
            iconBackground: const Color(0xFFFFEEF5),
            onTap: () => _requestVolunteerHelp(context),
          ),
          ShellActionCard(
            title: 'View Volunteer Profiles',
            subtitle: 'Browse verified volunteers who can assist you.',
            icon: Icons.groups_2_rounded,
            iconColor: const Color(0xFF169C63),
            iconBackground: const Color(0xFFE9F9F1),
            onTap: () => NavHelper.replaceWith(context, const VolunteerProfilesScreen()),
          ),
          ShellActionCard(
            title: 'View My Help Requests',
            subtitle: 'Track the status of your help requests.',
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFF5B34E6),
            iconBackground: const Color(0xFFEDE7FF),
            onTap: () => NavHelper.replaceWith(
              context,
              const HelpRequestsScreen(
                isVolunteer: false,
                title: 'My Help Requests',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
