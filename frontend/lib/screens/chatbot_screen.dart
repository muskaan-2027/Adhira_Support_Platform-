import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/floating_robot.dart';
import '../widgets/user_shell_layout.dart';
import 'community_screen.dart';
import 'help_requests_screen.dart';
import 'need_guidance_screen.dart';
import 'profile_screen.dart';
import 'sos_screen.dart';
import 'user_dashboard_screen.dart';
import 'volunteer_dashboard_screen.dart';
import 'volunteer_profiles_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'bot',
      'text': 'Hello! I\'m Sophie, your AI assistant.\nHow can I help you today?',
      'time': _formatTime(DateTime.now()),
    }
  ];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  
  String _selectedLanguage = 'English';
  final List<String> _languages = [
    'English', 'Hindi', 'Marathi', 'Bengali', 
    'Bhojpuri', 'Telugu', 'Kannada', 'Tamil'
  ];

  static String _formatTime(DateTime time) {
    int hour = time.hour;
    String period = 'AM';
    if (hour >= 12) {
      period = 'PM';
      if (hour > 12) hour -= 12;
    }
    if (hour == 0) hour = 12;
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final history = _messages.map((m) => {
      'sender': m['sender'] ?? '',
      'text': m['text'] ?? '',
    }).toList();

    setState(() {
      _messages.add({
        'sender': 'user', 
        'text': text,
        'time': _formatTime(DateTime.now()),
      });
      _isLoading = true;
    });

    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    try {
      final response = await ApiService.chatbot(
        message: text,
        language: _selectedLanguage,
        history: history,
      );
      final reply = response['reply']?.toString() ?? 'No response';
      setState(() {
        _messages.add({
          'sender': 'bot', 
          'text': reply,
          'time': _formatTime(DateTime.now()),
        });
      });
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(
        context,
        err.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _replaceWith(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _updateAvailability(bool active) async {
    try {
      await context
          .read<AuthService>()
          .updateVolunteerAvailability(active ? 'active' : 'inactive');
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(
        context,
        err.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _showAvailabilityDialog(BuildContext context, bool isActive) {
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
            onPressed: () {
              Navigator.pop(context);
              _updateAvailability(!isActive);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  List<UserNavItem> _getNavItems(BuildContext context, String role, bool isActive) {
    if (role == 'volunteer') {
      return [
        UserNavItem(
          label: 'Dashboard',
          icon: Icons.home_outlined,
          section: UserNavSection.dashboard,
          onTap: () => _replaceWith(context, const VolunteerDashboardScreen()),
        ),
        UserNavItem(
          label: 'Requests',
          icon: Icons.grid_view_rounded,
          section: UserNavSection.requests,
          onTap: () => _replaceWith(
            context,
            const HelpRequestsScreen(
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
          onTap: () => _replaceWith(
            context,
            const HelpRequestsScreen(
              isVolunteer: true,
              statusFilter: 'accepted',
              title: 'Assigned Requests',
            ),
          ),
        ),
        UserNavItem(
          label: 'Completed Work',
          icon: Icons.task_alt_rounded,
          section: UserNavSection.completedWork,
          onTap: () => _replaceWith(
            context,
            const HelpRequestsScreen(
              isVolunteer: true,
              statusFilter: 'completed',
              title: 'Completed Assistance',
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
          label: 'Community',
          icon: Icons.group_outlined,
          section: UserNavSection.community,
          onTap: () => _replaceWith(context, const CommunityScreen()),
        ),
        UserNavItem(
          label: 'Chat Assistant',
          icon: Icons.smart_toy_outlined,
          section: UserNavSection.chatbot,
          onTap: () {},
        ),
        UserNavItem(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          section: UserNavSection.profile,
          onTap: () => _replaceWith(context, const ProfileScreen()),
        ),
      ];
    } else {
      return [
        UserNavItem(
          label: 'Dashboard',
          icon: Icons.home_outlined,
          section: UserNavSection.dashboard,
          onTap: () => _replaceWith(context, const UserDashboardScreen()),
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
          onTap: () {},
        ),
        UserNavItem(
          label: 'My Help Requests',
          icon: Icons.assignment_outlined,
          section: UserNavSection.helpRequests,
          onTap: () => _replaceWith(
            context,
            const HelpRequestsScreen(
              isVolunteer: false,
              title: 'My Help Requests',
            ),
          ),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final role = user?.role ?? 'user';
    final isActive = user?.volunteerAvailability == 'active';
    final userName = user?.name.isNotEmpty == true ? user!.name : 'User';

    final navItems = _getNavItems(context, role, isActive);

    return UserShellLayout(
      selectedSection: UserNavSection.chatbot,
      title: 'Chatbot Assistant',
      subtitle: 'Chat with our AI assistant anytime for quick help and information.',
      userName: userName,
      accountRole: role == 'volunteer' ? 'Volunteer' : 'User',
      statusText: role == 'volunteer' ? 'Active' : 'Stay Safe',
      onProfileTap: () => _replaceWith(context, const ProfileScreen()),
      onLogout: () => context.read<AuthService>().logout(),
      onBackTap: () {
        if (role == 'volunteer') {
          _replaceWith(context, VolunteerDashboardScreen());
        } else {
          _replaceWith(context, UserDashboardScreen());
        }
      },
      navItems: navItems,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          final leftInfoCard = Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat with Sophie',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Your AI Assistant',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'I can help you with:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildChecklistItem('Safety tips and guidance'),
                      _buildChecklistItem('Emotional support'),
                      _buildChecklistItem('Information and resources'),
                      _buildChecklistItem('Finding the right help'),
                      const SizedBox(height: 20),
                      Center(
                        child: FloatingRobot(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.5),
                                      AppColors.primary.withOpacity(0.1),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.smart_toy_rounded,
                                  size: 80,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final rightChatInterface = Container(
            height: isWide ? 600 : 500,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chat History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F8FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            isDense: true,
                            icon: const Icon(Icons.language_rounded, color: AppColors.primary, size: 18),
                            items: _languages.map((String lang) {
                              return DropdownMenuItem<String>(
                                value: lang,
                                child: Text(lang, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedLanguage = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return ChatBubble(
                        text: msg['text'] ?? '',
                        isUser: msg['sender'] == 'user',
                        time: msg['time'] ?? '',
                      );
                    },
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: const TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _sendMessage,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: leftInfoCard),
                const SizedBox(width: 24),
                Expanded(flex: 6, child: rightChatInterface),
              ],
            );
          }

          return Column(
            children: [
              leftInfoCard,
              const SizedBox(height: 24),
              rightChatInterface,
            ],
          );
        },
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_rounded, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}