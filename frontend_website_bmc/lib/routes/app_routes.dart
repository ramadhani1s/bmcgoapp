import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/admin_dashboard.dart';
import '../screens/dashboard/mentor_dashboard.dart';
import '../services/auth_service.dart';

class AppRoutes {
  static const String login = '/login';
  static const String adminDashboard = '/admin-dashboard';
  static const String mentorDashboard = '/mentor-dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case mentorDashboard:
        return MaterialPageRoute(builder: (_) => const MentorDashboard());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Halaman tidak ditemukan'),
            ),
          ),
        );
    }
  }

  // Method untuk menentukan initial route berdasarkan status login
  static Future<String> getInitialRoute() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      return login;
    }

    final user = await AuthService.getCurrentUser();
    if (user == null) {
      return login;
    }

    // Validate token dengan backend
    final isValidToken = await AuthService.validateToken();
    if (!isValidToken) {
      await AuthService.logout();
      return login;
    }

    // Redirect berdasarkan role
    if (user.isAdmin) {
      return adminDashboard;
    } else if (user.isMentor) {
      return mentorDashboard;
    } else {
      // Jika role tidak didukung, logout dan redirect ke login
      await AuthService.logout();
      return login;
    }
  }
}