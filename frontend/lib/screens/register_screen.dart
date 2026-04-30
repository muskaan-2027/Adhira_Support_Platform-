import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  String _role = 'user';

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    try {
      await context.read<AuthService>().register(
            name.text.trim(),
            email.text.trim(),
            password.text,
            _role,
          );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(context, err.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthService>().loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 12),
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Register as',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  RadioListTile<String>(
                    value: 'user',
                    groupValue: _role,
                    onChanged: (value) => setState(() => _role = value ?? 'user'),
                    title: const Text('User'),
                  ),
                  RadioListTile<String>(
                    value: 'volunteer',
                    groupValue: _role,
                    onChanged: (value) => setState(() => _role = value ?? 'volunteer'),
                    title: const Text('Volunteer'),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(label: 'Sign Up', onPressed: _register, loading: loading),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
