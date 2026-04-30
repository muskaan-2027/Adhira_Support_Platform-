import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/user_shell_layout.dart';
import '../screens/chatbot_screen.dart';
import '../screens/community_screen.dart';
import '../screens/help_requests_screen.dart';
import '../screens/know_community_screen.dart';
import '../screens/need_guidance_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/profile_dashboard_screen.dart';
import '../screens/sos_screen.dart';
import '../screens/user_dashboard_screen.dart';
import '../screens/volunteer_dashboard_screen.dart';
import '../screens/volunteer_profiles_screen.dart';

class NavHelper {
  static void replaceWith(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  static void push(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  static void _showAvailabilityDialog(BuildContext context, bool isActive) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Availability'),
        content: Text(
            isActive ? 'Mark yourself inactive?' : 'Mark yourself active?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context
                    .read<AuthService>()
                    .updateVolunteerAvailability(isActive ? 'inactive' : 'active');
              } catch (err) {
                if (!context.mounted) return;
                NotificationService.showMessage(
                  context,
                  err.toString().replaceFirst('Exception: ', ''),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  static List<UserNavItem> getNavItems(BuildContext context, AppUser? user) {
    if (user?.role == 'volunteer') {
      final isActive = user?.volunteerAvailability == 'active';
      return [
        UserNavItem(
          label: 'Dashboard',
          icon: Icons.home_outlined,
          section: UserNavSection.dashboard,
          onTap: () => replaceWith(context, VolunteerDashboardScreen()),
        ),
        UserNavItem(
          label: 'Requests',
          icon: Icons.grid_view_rounded,
          section: UserNavSection.requests,
          onTap: () => replaceWith(
            context,
            HelpRequestsScreen(
              isVolunteer: true,
              statusFilter: 'pending',
              title: 'Pending Help Requests',
            ),
          ),
        ),
        UserNavItem(
          label: 'My Assignments',
          icon: Icons.playlist_add_check_rounded,
          section: UserNavSection.assignments,
          onTap: () => replaceWith(
            context,
            HelpRequestsScreen(
              isVolunteer: true,
              statusFilter: 'accepted',
              title: 'Assigned Requests',
            ),
          ),
        ),

        UserNavItem(
          label: 'Availability',
          icon: Icons.calendar_month_outlined,
          section: UserNavSection.availability,
          onTap: () => _showAvailabilityDialog(context, isActive),
        ),
        UserNavItem(
          label: 'Know Your Community',
          icon: Icons.people_outline_rounded,
          section: UserNavSection.knowCommunity,
          onTap: () => replaceWith(context, KnowCommunityScreen()),
        ),
        UserNavItem(
          label: 'Community',
          icon: Icons.group_outlined,
          section: UserNavSection.community,
          onTap: () => replaceWith(context, CommunityScreen()),
        ),
        UserNavItem(
          label: 'Chat Assistant',
          icon: Icons.smart_toy_outlined,
          section: UserNavSection.chatbot,
          onTap: () => replaceWith(context, ChatbotScreen()),
        ),
        UserNavItem(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          section: UserNavSection.profile,
          onTap: () => replaceWith(context, ProfileDashboardScreen()),
        ),
      ];
    } else {
      return [
        UserNavItem(
          label: 'Dashboard',
          icon: Icons.home_outlined,
          section: UserNavSection.dashboard,
          onTap: () => replaceWith(context, UserDashboardScreen()),
        ),
        UserNavItem(
          label: 'Emergency SOS',
          icon: Icons.warning_amber_rounded,
          section: UserNavSection.sos,
          onTap: () => replaceWith(context, SOSScreen()),
        ),
        UserNavItem(
          label: 'Need Guidance',
          icon: Icons.support_agent_rounded,
          section: UserNavSection.needGuidance,
          onTap: () => replaceWith(context, NeedGuidanceScreen()),
        ),
        UserNavItem(
          label: 'Volunteer Profiles',
          icon: Icons.groups_2_outlined,
          section: UserNavSection.volunteers,
          onTap: () => replaceWith(context, VolunteerProfilesScreen()),
        ),
        UserNavItem(
          label: 'Know Your Community',
          icon: Icons.people_outline_rounded,
          section: UserNavSection.knowCommunity,
          onTap: () => replaceWith(context, KnowCommunityScreen()),
        ),
        UserNavItem(
          label: 'Community',
          icon: Icons.forum_outlined,
          section: UserNavSection.community,
          onTap: () => replaceWith(context, CommunityScreen()),
        ),
        UserNavItem(
          label: 'Chatbot Assistant',
          icon: Icons.chat_bubble_outline_rounded,
          section: UserNavSection.chatbot,
          onTap: () => replaceWith(context, ChatbotScreen()),
        ),
        UserNavItem(
          label: 'My Help Requests',
          icon: Icons.assignment_outlined,
          section: UserNavSection.helpRequests,
          onTap: () => replaceWith(
              context,
              HelpRequestsScreen(
                isVolunteer: false,
                title: 'My Help Requests',
              )),
        ),
        UserNavItem(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          section: UserNavSection.profile,
          onTap: () => replaceWith(context, ProfileDashboardScreen()),
        ),
      ];
    }
  }
}
