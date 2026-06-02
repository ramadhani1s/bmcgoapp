import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/screens/auth/auth_entry_screen.dart';
import 'package:frontend_mobile_bmc/screens/auth/login_screen.dart';
import 'package:frontend_mobile_bmc/screens/auth/register_screen.dart';
import 'package:frontend_mobile_bmc/screens/home/dashboard_screen.dart';
import 'package:frontend_mobile_bmc/screens/home/attendance_screen.dart';
import 'package:frontend_mobile_bmc/screens/home/package_screen.dart';
import 'package:frontend_mobile_bmc/screens/home/theme_provider.dart';
import 'package:provider/provider.dart';

import 'package:frontend_mobile_bmc/screens/home/profile_detail_form_screen.dart';
import 'package:frontend_mobile_bmc/screens/onboarding_screen.dart';
import 'package:frontend_mobile_bmc/screens/splash_screen.dart';
import 'package:frontend_mobile_bmc/screens/payment/payment_history_screen.dart';
import 'package:frontend_mobile_bmc/screens/siswa/materi_screen.dart';
import 'package:frontend_mobile_bmc/screens/siswa/materi_detail_screen.dart';
import 'package:frontend_mobile_bmc/screens/siswa/latihan_dari_materi_screen.dart';
import 'package:frontend_mobile_bmc/screens/siswa/pengumuman_screen.dart';
import 'package:frontend_mobile_bmc/screens/siswa/olimpiade_screen.dart';
import 'package:frontend_mobile_bmc/screens/tryout/tryout_list_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/local_notification_service.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await LocalNotificationService.init();

  FirebaseMessaging.onMessage.listen(
    (RemoteMessage message) async {

      print(message.notification?.title);
      print(message.notification?.body);

      await LocalNotificationService.showNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
      );
    },
  );

  await FirebaseMessaging.instance.requestPermission();

  String? token =
      await FirebaseMessaging.instance.getToken();

  print("FCM TOKEN: $token");

  runApp(

    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),

  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {

        return MaterialApp(

          debugShowCheckedModeBanner: false,

          title: 'Bimbel Bintang Muda Center',

          themeMode: themeProvider.themeMode,

          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B82F6),
              brightness: Brightness.light,
            ),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
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
            '/profile-detail': (context) =>
                const ProfileDetailFormScreen(),
            '/package': (context) => const PackageScreen(),
            '/payment-history': (context) =>
                const PaymentHistoryScreen(),
            '/payment': (context) =>
                const PaymentHistoryScreen(),
            '/materi': (context) => const MateriScreen(),
            '/pengumuman': (context) =>
                const PengumumanScreen(),
            '/olimpiade': (context) =>
                const OlimpiadeScreen(),
            '/mentor-tryout': (context) =>
                const TryOutListScreen(),
          },

          onGenerateRoute: (settings) {
            if (settings.name == '/materi-detail') {
              final materi = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => MateriDetailScreen(materi: materi),
              );
            } else if (settings.name == '/latihan-dari-materi') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => LatihanDariMateriScreen(
                  subject: args['subject'] as String,
                  materiTitle: args['materi_title'] as String,
                ),
              );
            }
            return null;
          },
        );
      },
    );
  }
}