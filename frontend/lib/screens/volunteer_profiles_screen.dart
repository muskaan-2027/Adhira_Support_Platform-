import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/volunteer_profile_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/nav_helper.dart';
import '../widgets/user_shell_layout.dart';
import 'profile_screen.dart';
import 'volunteer_profile_screen.dart';

class VolunteerProfilesScreen extends StatefulWidget {
  const VolunteerProfilesScreen({super.key});

  @override
  State<VolunteerProfilesScreen> createState() => _VolunteerProfilesScreenState();
}

class _VolunteerProfilesScreenState extends State<VolunteerProfilesScreen> {
  bool _loading = false;
  List<VolunteerProfileModel> _volunteers = [];
  String _searchQuery = '';
  String? _expandedVolunteerId;
  final TextEditingController _inlineRequestController = TextEditingController();
  bool _submittingInlineRequest = false;

  @override
  void initState() {
    super.initState();
    _loadVolunteers();
  }

  Future<void> _loadVolunteers() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');
      final response = await ApiService.getVolunteerProfiles(token, onlyActive: false);
      final list = response['volunteers'] as List<dynamic>? ?? [];
      if (mounted) {
        setState(() {
          _volunteers = list
              .whereType<Map<String, dynamic>>()
              .map(VolunteerProfileModel.fromJson)
              .toList();
        });
      }
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(context, err.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendRequest(VolunteerProfileModel volunteer) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Request ${volunteer.name}'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Describe what support you need'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Send Help Request'),
          ),
        ],
      ),
    );

    if (message == null || message.isEmpty) return;
    if (!mounted) return;
    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');
      await ApiService.createHelpRequest(token, message: message, volunteerId: volunteer.id);
      if (!mounted) return;
      NotificationService.showMessage(context, 'Help request sent to ${volunteer.name}');
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(context, err.toString().replaceFirst('Exception: ', ''));
    }
  }



  Future<void> _rateVolunteer(VolunteerProfileModel volunteer) async {
    int selectedRating = 5;
    final reviewController = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Rate ${volunteer.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share your experience', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(
                    i < selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFFDB528),
                    size: 36,
                  ),
                  onPressed: () => setState(() => selectedRating = i + 1),
                )),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write your review (optional)...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {'rating': selectedRating, 'review': reviewController.text.trim()}),
              child: const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    if (!mounted) return;
    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');
      await ApiService.rateVolunteerProfile(token, volunteer.id, result['rating'], result['review']);
      await _loadVolunteers();
      if (!mounted) return;
      NotificationService.showMessage(context, 'Rating submitted!');
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(context, err.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'User';

    final filtered = _volunteers.where((v) {
      final q = _searchQuery.toLowerCase();
      return v.name.toLowerCase().contains(q) ||
          v.occupation.toLowerCase().contains(q) ||
          v.areasOfHelp.toLowerCase().contains(q) ||
          v.city.toLowerCase().contains(q);
    }).toList();

    return UserShellLayout(
      selectedSection: UserNavSection.volunteers,
      title: 'Volunteer Profiles',
      subtitle: 'Connect with verified volunteers who can help and support you.',
      userName: userName,
      accountRole: user?.role == 'volunteer' ? 'Volunteer' : 'User',
      statusText: 'Stay Safe',
      onProfileTap: () => NavHelper.replaceWith(context, const ProfileScreen()),
      onLogout: () => context.read<AuthService>().logout(),
      navItems: NavHelper.getNavItems(context, user),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search row
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search volunteers by name, skill or location',
                    prefixIcon: const Icon(Icons.search, color: Colors.black45),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list_rounded),
                label: const Text('Filters'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Volunteer list
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Text('No volunteers found.', style: TextStyle(color: Colors.black54, fontSize: 16)),
            )
          else
            ...filtered.map((v) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _volunteerCard(v),
            )),
          const SizedBox(height: 16),
          // Bottom banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF2EEFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your safety is our priority.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      SizedBox(height: 2),
                      Text(
                        'All volunteers are verified. You can view their profile before sending a request.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _volunteerCard(VolunteerProfileModel v) {
    final location = [v.city, v.state].where((e) => e.isNotEmpty).join(', ');
    final experience = v.yearsOfExperience.isNotEmpty ? '${v.yearsOfExperience}+ years experience' : 'Experienced';
    final speciality = v.areasOfHelp.isNotEmpty ? 'Expert in ${v.areasOfHelp}' : v.occupation;
    final initial = v.name.isNotEmpty ? v.name[0].toUpperCase() : 'V';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFFEDE7FF),
                      child: Text(initial,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 26)),
                    ),
                    if (v.voterIdVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.verified_rounded,
                              color: Color(0xFF188A56), size: 18),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                // Name + role + rating
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(v.occupation,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _rateVolunteer(v),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9EE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFDB528), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${v.averageRating.toStringAsFixed(1)} (${v.totalRatings} reviews)',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8A5E00)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Details column
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow(Icons.work_outline_rounded, experience),
                      const SizedBox(height: 8),
                      _detailRow(Icons.school_outlined, speciality),
                      const SizedBox(height: 8),
                      _detailRow(Icons.location_on_outlined,
                          location.isNotEmpty ? location : 'India'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => NavHelper.push(
                          context, VolunteerProfileScreen(volunteerId: v.id)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(130, 42),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      child: const Text('View Profile',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (_expandedVolunteerId == v.id) {
                            _expandedVolunteerId = null;
                          } else {
                            _expandedVolunteerId = v.id;
                            _inlineRequestController.clear();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _expandedVolunteerId == v.id
                            ? const Color(0xFFF5F5F5)
                            : AppColors.primary,
                        foregroundColor: _expandedVolunteerId == v.id
                            ? Colors.black87
                            : Colors.white,
                        minimumSize: const Size(130, 42),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                          _expandedVolunteerId == v.id ? 'Cancel' : 'Request Help',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_expandedVolunteerId == v.id) _buildInlineRequestSection(v),
        ],
      ),
    );
  }

  Widget _buildInlineRequestSection(VolunteerProfileModel v) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F8FF),
        border: Border(top: BorderSide(color: Color(0xFFE8E8EE))),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.handshake_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tell us how this volunteer can help you',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _inlineRequestController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Describe your situation or the specific assistance you need from ${v.name}...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _expandedVolunteerId = null),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 160),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submittingInlineRequest
                        ? null
                        : () => _submitInlineRequest(v),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _submittingInlineRequest
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Send Help Request',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitInlineRequest(VolunteerProfileModel volunteer) async {
    final message = _inlineRequestController.text.trim();
    if (message.isEmpty) {
      NotificationService.showMessage(context, 'Please describe your request');
      return;
    }

    setState(() => _submittingInlineRequest = true);
    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');
      await ApiService.createHelpRequest(token,
          message: message, volunteerId: volunteer.id);
      if (!mounted) return;
      setState(() {
        _expandedVolunteerId = null;
        _inlineRequestController.clear();
      });
      NotificationService.showMessage(
          context, 'Help request sent successfully to ${volunteer.name}');
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(
          context, err.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submittingInlineRequest = false);
    }
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
