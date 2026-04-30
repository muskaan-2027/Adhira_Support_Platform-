import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

class SafetyAppsScreen extends StatelessWidget {
  const SafetyAppsScreen({super.key});

  final List<Map<String, dynamic>> _allSafetyApps = const [
    {
      'name': 'bSafe',
      'icon': Icons.security_rounded,
      'color': Color(0xFF7B61FF),
      'desc': 'Personal safety app with SOS & live location.',
      'rating': '4.6',
      'url': 'https://play.google.com/store/apps/details?id=com.bsafe',
    },
    {
      'name': 'Raksha',
      'icon': Icons.shield_outlined,
      'color': Color(0xFFE11D48),
      'desc': 'Smart safety app for women\'s security.',
      'rating': '4.4',
      'url': 'https://play.google.com/store/search?q=raksha%20women%20safety&c=apps',
    },
    {
      'name': 'Himmat',
      'icon': Icons.health_and_safety_rounded,
      'color': Color(0xFFEAB308),
      'desc': 'Quick SOS alerts and real-time tracking.',
      'rating': '4.5',
      'url': 'https://play.google.com/store/search?q=himmat%20app&c=apps',
    },
    {
      'name': 'Circle of 6',
      'icon': Icons.group_rounded,
      'color': Color(0xFF14B8A6),
      'desc': 'Your trusted circle for safety & support.',
      'rating': '4.3',
      'url': 'https://play.google.com/store/apps/details?id=com.circleof6.v2',
    },
    {
      'name': 'My Safetipin',
      'icon': Icons.location_on_rounded,
      'color': Color(0xFFEC4899),
      'desc': 'Safety score for streets and neighborhoods.',
      'rating': '4.5',
      'url': 'https://play.google.com/store/apps/details?id=com.safetipin.mysafetipin',
    },
    {
      'name': 'Shake2Safety',
      'icon': Icons.vibration_rounded,
      'color': Color(0xFFF97316),
      'desc': 'Shake your phone to send SOS and audio.',
      'rating': '4.2',
      'url': 'https://play.google.com/store/search?q=shake2safety&c=apps',
    },
  ];

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the app link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Other Safety Apps'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: _allSafetyApps.length,
        itemBuilder: (context, index) {
          final app = _allSafetyApps[index];
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))
              ]
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: app['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(app['icon'], color: app['color'], size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  app['name'],
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    app['desc'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 3,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      app['rating'],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 18),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _launchUrl(context, app['url']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
