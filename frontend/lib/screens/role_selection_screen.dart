import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_button.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _role = 'user';

  Future<void> _saveRole() async {
    try {
      await context.read<AuthService>().updateRole(_role);
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(
        context,
        err.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Role'),
        actions: [
          TextButton(
            onPressed: auth.loading ? null : () => auth.logout(),
            child: const Text('Logout'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                const Text(
                  'How do you want to use the app?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  value: 'user',
                  groupValue: _role,
                  onChanged: (value) => setState(() => _role = value ?? 'user'),
                  title: const Text('User'),
                  subtitle: const Text('Request support and access safety features'),
                ),
                RadioListTile<String>(
                  value: 'volunteer',
                  groupValue: _role,
                  onChanged: (value) => setState(() => _role = value ?? 'volunteer'),
                  title: const Text('Volunteer'),
                  subtitle: const Text('Help users and handle assigned support requests'),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  label: 'Continue',
                  onPressed: _saveRole,
                  loading: auth.loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
