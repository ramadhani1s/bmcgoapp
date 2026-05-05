import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/screens/auth/auth_entry_screen.dart';
import 'package:frontend_mobile_bmc/screens/auth/login_screen.dart';
import 'package:frontend_mobile_bmc/screens/auth/register_screen.dart';
import 'package:frontend_mobile_bmc/screens/home/dashboard_screen.dart';
import 'package:frontend_mobile_bmc/screens/home/attendance_screen.dart';
import 'package:frontend_mobile_bmc/screens/home/package_screen.dart';

import 'package:frontend_mobile_bmc/screens/home/profile_detail_form_screen.dart';
import 'package:frontend_mobile_bmc/screens/onboarding_screen.dart';
import 'package:frontend_mobile_bmc/screens/splash_screen.dart';
import 'package:frontend_mobile_bmc/screens/payment/payment_history_screen.dart';
import 'package:frontend_mobile_bmc/screens/siswa/materi_screen.dart';
import 'package:frontend_mobile_bmc/screens/siswa/pengumuman_screen.dart';
import 'package:frontend_mobile_bmc/screens/siswa/olimpiade_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bimbel Bintang Muda Center',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/entry': (context) => const AuthEntryScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        
        '/profile-detail': (context) => const ProfileDetailFormScreen(),
        '/package': (context) => const PackageScreen(),
        '/payment-history': (context) => const PaymentHistoryScreen(),
        '/payment': (context) => const PaymentHistoryScreen(),
        '/materi': (context) => const MateriScreen(),
        '/pengumuman': (context) => const PengumumanScreen(),
        '/olimpiade': (context) => const OlimpiadeScreen(),
      },
    );
  }
}