import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/user_shell_layout.dart';
import '../utils/nav_helper.dart';
import '../models/user_model.dart';
import 'chatbot_screen.dart';
import 'community_screen.dart';
import 'help_requests_screen.dart';
import 'need_guidance_screen.dart';
import 'profile_screen.dart';
import 'user_dashboard_screen.dart';
import 'volunteer_profiles_screen.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  final _notesController = TextEditingController();
  bool _loading = false;
  String _locationLabel = 'Location not captured';
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // removed custom nav logic
  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Enable location services to send SOS');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required to send SOS');
    }

    return Geolocator.getCurrentPosition();
  }

  Future<void> _sendSOS() async {
    setState(() => _loading = true);

    try {
      final token = context.read<AuthService>().token;
      final user = context.read<AuthService>().currentUser;
      if (token == null) throw Exception('Please login again');

      final position = await _getCurrentPosition();
      await ApiService.sendSOS(
        token,
        lat: position.latitude,
        lng: position.longitude,
        notes: _notesController.text.trim(),
      );

      setState(() {
        _locationLabel = '${position.latitude}, ${position.longitude}';
      });

      // Notify emergency contacts via SMS
      if (user != null && user.emergencyContacts.isNotEmpty) {
        final phones = user.emergencyContacts.map((c) => c.phone).join(',');
        final locationUrl = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
        final message = 'SOS EMERGENCY! I need help. My location: $locationUrl. ${_notesController.text.trim()}';
        
        final uri = Uri.parse('sms:$phones?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }

      _notesController.clear();
      await _loadHistory();
      if (!mounted) return;
      NotificationService.showMessage(
          context, 'Emergency alert sent successfully');
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

  Future<void> _loadHistory() async {
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;
      final response = await ApiService.getSOSHistory(token);
      final list = response['history'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _history = list.whereType<Map<String, dynamic>>().toList();
      });
    } catch (_) {
      // non-blocking
    }
  }

  Future<void> _addContact() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );

    if (result != true) return;
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;

    if (!mounted) return;
    try {
      final token = context.read<AuthService>().token;
      if (token == null) throw Exception('Please login again');
      
      final res = await ApiService.addEmergencyContact(token, nameCtrl.text.trim(), phoneCtrl.text.trim());
      await context.read<AuthService>().refreshProfile(); // Refresh user state
      if (!mounted) return;
      NotificationService.showMessage(context, 'Contact added');
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(context, 'Failed to add contact');
    }
  }

  Future<void> _removeContact(String id) async {
    if (id.isEmpty) {
      NotificationService.showMessage(context, 'Cannot delete: contact has no ID. Please re-add the contact.');
      return;
    }
    try {
      final token = context.read<AuthService>().token;
      if (token == null) return;
      await ApiService.removeEmergencyContact(token, id);
      await context.read<AuthService>().refreshProfile();
      if (!mounted) return;
      NotificationService.showMessage(context, 'Contact removed');
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(context, 'Failed to remove: ${err.toString().replaceFirst('Exception: ', '')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final userName = user?.name ?? 'User';
    return UserShellLayout(
      selectedSection: UserNavSection.sos,
      title: 'SOS Emergency',
      subtitle:
          'Press the SOS button in an emergency. Your location will be shared instantly.',
      userName: userName,
      accountRole: user?.role == 'volunteer' ? 'Volunteer' : 'User',
      statusText: 'Stay Safe',
      supportHeadline: 'You are not alone.',
      supportMessage: 'Help is just a tap away.\nStay aware. Stay safe.',
      supportIcon: Icons.health_and_safety_rounded,
      onProfileTap: () => NavHelper.replaceWith(context, const ProfileScreen()),
      onLogout: () => context.read<AuthService>().logout(),
      navItems: NavHelper.getNavItems(context, user),
      child: Column(
        children: [
          _heroCard(),
          const SizedBox(height: 14),
          _emergencyContactsCard(user),
          const SizedBox(height: 14),
          _historyCard(),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;

          final leftContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE9EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: Color(0xFFDC284C),
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Press SOS in Emergency',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC284C),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'We will notify your emergency contacts and nearby volunteers with your live location.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Emergency notes (optional)',
                  hintText: 'Describe your emergency briefly',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Current location: $_locationLabel',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          );

          final centerContent = Center(
            child: GestureDetector(
              onTap: _loading ? null : _sendSOS,
              child: Container(
                width: 250,
                height: 250,
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEEF1),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: _loading
                        ? const Color(0xFFFF7088)
                        : const Color(0xFFFF294D),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x30FF294D),
                        blurRadius: 22,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _loading ? 'Sending...' : 'SOS\nPress SOS',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          const rightContent = Column(
            children: [
              _StatusTile(
                icon: Icons.location_on_outlined,
                title: 'Live Location',
                subtitle: 'Will be shared in real-time',
                iconColor: Color(0xFFDC284C),
                bgColor: Color(0xFFFFEEF1),
              ),
              SizedBox(height: 12),
              _StatusTile(
                icon: Icons.group_outlined,
                title: 'Alerts to Contacts',
                subtitle: 'Your emergency contacts will be notified',
                iconColor: AppColors.primary,
                bgColor: Color(0xFFF2EEFF),
              ),
              SizedBox(height: 12),
              _StatusTile(
                icon: Icons.shield_outlined,
                title: 'Volunteers Notified',
                subtitle: 'Nearby volunteers will be alerted to help you',
                iconColor: Color(0xFF188A56),
                bgColor: Color(0xFFEAF8F0),
              ),
            ],
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftContent,
                const SizedBox(height: 18),
                centerContent,
                const SizedBox(height: 18),
                rightContent,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftContent),
              const SizedBox(width: 20),
              Expanded(child: centerContent),
              const SizedBox(width: 20),
              const Expanded(child: rightContent),
            ],
          );
        },
      ),
    );
  }

  Widget _emergencyContactsCard(AppUser? user) {
    final contacts = user?.emergencyContacts ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.group_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              InkWell(
                onTap: _addContact,
                child: const Text(
                  '+ Add Contact',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (contacts.isEmpty)
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Text('No emergency contacts added yet.', style: TextStyle(color: AppColors.textMuted)),
             )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: contacts
                  .map(
                    (contact) => Container(
                      width: 250,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                        color: const Color(0xFFFCFCFF),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFF2EEFF),
                            child: Text(
                              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  contact.phone,
                                  style: const TextStyle(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeContact(contact.id),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _historyCard() {
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
          const Text(
            'SOS History',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_history.isEmpty)
            const Text(
              'No SOS logs yet',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            Column(
              children: _history.map((log) {
                final location = log['location'] as Map<String, dynamic>? ?? {};
                final createdAt = log['createdAt']?.toString() ?? 'Unknown date';
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEEF1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: Color(0xFFDC284C),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SOS Alert Sent',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lat: ${location['lat'] ?? 'N/A'}, Lng: ${location['lng'] ?? 'N/A'}',
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                            Text(
                              createdAt,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color bgColor;

  const _StatusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
              color: bgColor, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: iconColor, size: 30),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
