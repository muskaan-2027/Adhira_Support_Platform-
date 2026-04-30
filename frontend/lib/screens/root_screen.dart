import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'role_selection_screen.dart';
import 'user_dashboard_screen.dart';
import 'volunteer_dashboard_screen.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (!auth.initialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        if (auth.currentUser?.role == null) {
          return const RoleSelectionScreen();
        }

        if (auth.needsOnboarding) {
          return const ProfileScreen();
        }

        if (auth.currentUser?.role == 'volunteer') {
          return const VolunteerDashboardScreen();
        }

        return const UserDashboardScreen();
      },
    );
  }
}
