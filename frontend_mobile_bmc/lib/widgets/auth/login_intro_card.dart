import 'package:flutter/material.dart';

class LoginIntroCard extends StatelessWidget {
  const LoginIntroCard({super.key});

  static const Color _labelColor = Color(0xFF25293B);
  static const Color _pillBg = Color(0xFFEDEDED);
  static const Color _pillText = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F0E5),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Image.asset(
              'assets/images/bmc_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Selamat Datang!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _labelColor,
            fontSize: 31,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.35,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Silahkan masuk ke akun Anda',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF9AA0AE),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _pillBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'BINTANG MUDA CENTER',
              style: TextStyle(
                color: _pillText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}