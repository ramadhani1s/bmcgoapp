import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/admin_dashboard.dart';
import '../screens/mentor/mentor_dashboard.dart';
import '../screens/dashboard/mentor_attendance_screen.dart';
import '../screens/dashboard/mentor_olimpiade_screen.dart';
import '../screens/dashboard/mentor_profile_screen.dart';
import '../screens/dashboard/mentor_tryout_screen.dart';
import '../screens/dashboard/paket_les_screen.dart';
import '../screens/dashboard/soal_latihan_management_screen.dart';
import '../screens/mentor/evaluasi_siswa_screen.dart';
import '../screens/mentor/latihan_soal_screen.dart';
import '../screens/mentor/materi_pembelajaran_screen.dart';
import '../screens/dashboard/verifikasi_pendaftaran_screen.dart';
import '../screens/mentor_management_screen.dart';
import '../screens/payment_verification_screen.dart';
import '../services/auth_service.dart';
import '../screens/dashboard/admin_kelola_absensi_screen.dart';
import '../screens/dashboard/admin_kelola_alumni_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String adminDashboard = '/admin-dashboard';
  static const String paymentVerification = '/payment-verification';
  static const String mentorDashboard = '/mentor-dashboard';
  static const String mentorAttendance = '/mentor-attendance';
  static const String mentorProfile = '/mentor-profile';
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
        return MaterialPageRoute(builder: (_) => const MentorDashboard());

      case mentorAttendance:
        return MaterialPageRoute(
          builder: (_) => const MentorAttendanceScreen(),
        );

      case mentorProfile:
        return MaterialPageRoute(builder: (_) => const MentorProfileScreen());

      case mentorManagement:
        return MaterialPageRoute(
          builder: (_) => const VerifikasiPendaftaranScreen(),
        );

      case mentorExercise:
        return MaterialPageRoute(builder: (_) => const LatihanSoalScreen());

      case mentorTryout:
        return MaterialPageRoute(builder: (_) => const MentorTryoutScreen());

      case mentorOlimpiade:
        return MaterialPageRoute(builder: (_) => const MentorOlimpiadeScreen());

      case mentorEvaluasi:
        return MaterialPageRoute(builder: (_) => const EvaluasiSiswaScreen());

      case mentorMateri:
        return MaterialPageRoute(
          builder: (_) => const MateriPembelajaranScreen(),
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
