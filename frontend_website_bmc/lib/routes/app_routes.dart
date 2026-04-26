import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/admin_dashboard.dart';
import '../screens/dashboard/mentor_dashboard.dart';
import '../screens/dashboard/mentor_attendance_screen.dart';
import '../screens/dashboard/mentor_olimpiade_screen.dart';
import '../screens/dashboard/mentor_tryout_screen.dart';
import '../screens/dashboard/paket_les_screen.dart';
import '../screens/mentor/latihan_soal_screen.dart';
import '../screens/mentor/materi_pembelajaran_screen.dart';
import '../screens/mentor_management_screen.dart';
import '../screens/payment_verification_screen.dart';
import '../services/auth_service.dart';

class AppRoutes {
  static const String login = '/login';
  static const String adminDashboard = '/admin-dashboard';
  static const String paymentVerification = '/payment-verification';
  static const String mentorDashboard = '/mentor-dashboard';
  static const String mentorAttendance = '/mentor-attendance';
  static const String mentorManagement = '/mentor-management';
  static const String mentorExercise = '/mentor-exercise';
  static const String mentorTryout = '/mentor-tryout';
  static const String mentorOlimpiade = '/mentor-olimpiade';
  static const String mentorMateri = '/mentor-materi';
  static const String paketLes = '/paket-les';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
        );

      case paymentVerification:
        return MaterialPageRoute(
          builder: (_) => const PaymentVerificationScreen(),
        );

      case mentorDashboard:
        return MaterialPageRoute(
          builder: (_) => const MentorDashboard(),
        );

      case mentorAttendance:
        return MaterialPageRoute(
          builder: (_) => const MentorAttendanceScreen(),
        );

      case mentorManagement:
        return MaterialPageRoute(
          builder: (_) => const MentorManagementScreen(),
        );

      case mentorExercise:
        return MaterialPageRoute(
          builder: (_) => const LatihanSoalScreen(),
        );

      case mentorTryout:
        return MaterialPageRoute(
          builder: (_) => const MentorTryoutScreen(),
        );

      case mentorOlimpiade:
        return MaterialPageRoute(
          builder: (_) => const MentorOlimpiadeScreen(),
        );

      case mentorMateri:
        return MaterialPageRoute(
          builder: (_) => const MateriPembelajaranScreen(),
        );

      case paketLes:
        return MaterialPageRoute(
          builder: (_) => const PaketLesScreen(),
        );

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

  static Future<String> getInitialRoute() async {
    final isLoggedIn = await AuthService.isLoggedIn();

    if (!isLoggedIn) {
      return login;
    }

    final user = await AuthService.getCurrentUser();

    if (user == null) {
      return login;
    }

    final isValidToken = await AuthService.validateToken();

    if (!isValidToken) {
      await AuthService.logout();
      return login;
    }

    if (user.isAdmin) {
      return adminDashboard;
    } else if (user.isMentor) {
      return mentorDashboard;
    } else {
      await AuthService.logout();
      return login;
    }
  }
}