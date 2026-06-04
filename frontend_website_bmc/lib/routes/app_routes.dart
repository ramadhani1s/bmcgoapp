import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/mentor/mentor_screens.dart';
import '../screens/mentor_management_screen.dart';
import '../screens/dashboard/soal_latihan_management_screen.dart';
import '../screens/dashboard/mentor_attendance_screen.dart';
import '../screens/dashboard/mentor_olimpiade_screen.dart';
import '../screens/dashboard/mentor_profile_screen.dart';
import '../screens/dashboard/mentor_tryout_screen.dart';
import '../screens/dashboard/paket_les_screen.dart';
import '../screens/dashboard/verifikasi_pendaftaran_screen.dart';
import '../screens/dashboard/admin_dashboard.dart';
import '../screens/dashboard/admin_kelola_absensi_screen.dart';
import '../screens/dashboard/admin_kelola_alumni_screen.dart';
import '../screens/dashboard/admin_profile_screen.dart';
import '../services/auth_service.dart';

class AppRoutes {
  static const String login = '/login';
  static const String adminDashboard = '/admin-dashboard';
  static const String paymentVerification = '/payment-verification';
  static const String mentorDashboard = '/mentor-dashboard';
  static const String mentorAttendance = '/mentor-attendance';
  static const String mentorProfile = '/mentor-profile';
  static const String adminProfile = '/admin-profile';
  static const String mentorManagement = '/mentor-management';
  static const String mentorExercise = '/mentor-exercise';
  static const String mentorTryout = '/mentor-tryout';
  static const String mentorOlimpiade = '/mentor-olimpiade';

  static const String mentorEvaluasi = '/mentor-evaluasi';
  static const String mentorMateri = '/mentor-materi';

  static const String paketLes = '/paket-les';
  static const String soalLatihanManagement = '/soal-latihan-management';
  static const String adminKelolaAbsensi = '/admin-kelola-absensi';
  static const String adminKelolaAlumni = '/admin-kelola-alumni';
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case adminDashboard:
        final initialMenuTitle = settings.arguments is String
            ? settings.arguments as String
            : 'Dashboard';
        return MaterialPageRoute(
          builder: (_) => AdminDashboard(initialMenuTitle: initialMenuTitle),
        );

      case adminKelolaAbsensi:
        return MaterialPageRoute(
          builder: (_) => const AdminKelolaAbsensiScreen(),
        );

      case adminKelolaAlumni:
        return MaterialPageRoute(
          builder: (_) => const AdminKelolaAlumniScreen(),
        );

      case paymentVerification:
        return MaterialPageRoute(
          builder: (_) => const VerifikasiPendaftaranScreen(),
        );

      case mentorDashboard:
        return InstantPageRoute(child: const MentorDashboard(), settings: settings);

      case mentorAttendance:
        return InstantPageRoute(
          child: const MentorAttendanceScreen(),
          settings: settings,
        );

      case mentorProfile:
        return InstantPageRoute(child: const MentorProfileScreen(), settings: settings);

      case adminProfile:
        return MaterialPageRoute(builder: (_) => const AdminProfileScreen());

      case mentorManagement:
        return InstantPageRoute(
          child: const MentorManagementScreen(),
          settings: settings,
        );

      case mentorExercise:
        return InstantPageRoute(child: const LatihanSoalScreen(), settings: settings);

      case mentorTryout:
        return InstantPageRoute(child: const MentorTryoutScreen(), settings: settings);

      case mentorOlimpiade:
        return InstantPageRoute(child: const MentorOlimpiadeScreen(), settings: settings);

      case mentorEvaluasi:
        return InstantPageRoute(child: const EvaluasiSiswaScreen(), settings: settings);

      case mentorMateri:
        return InstantPageRoute(
          child: const MateriPembelajaranScreen(),
          settings: settings,
        );

      case paketLes:
        return MaterialPageRoute(builder: (_) => const PaketLesScreen());

      case soalLatihanManagement:
        return MaterialPageRoute(
          builder: (_) => const SoalLatihanManagementScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Halaman tidak ditemukan')),
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

class InstantPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  InstantPageRoute({required this.child, RouteSettings? settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          settings: settings,
        );
}
