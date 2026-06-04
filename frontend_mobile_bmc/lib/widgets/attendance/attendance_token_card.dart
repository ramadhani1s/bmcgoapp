import 'package:flutter/material.dart';
import 'attendance_card_shell.dart';

class AttendanceTokenCard extends StatelessWidget {
  const AttendanceTokenCard({
    super.key,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
    this.activeSession,
    required this.remainingTime,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final Map<String, dynamic>? activeSession;
  final Duration remainingTime;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return AttendanceCardShell(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.tag_rounded,
              size: 34,
              color: Color(0xFFFB7185),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Kode Token Absensi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dapatkan token 6 karakter dari mentor Anda',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), height: 1.45),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 22,
              letterSpacing: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '0 0 0 0 0 0',
              hintStyle: const TextStyle(
                letterSpacing: 8,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 22,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFFB7185),
                  width: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (activeSession != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: remainingTime == Duration.zero ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: remainingTime == Duration.zero ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.class_rounded,
                        size: 18,
                        color: remainingTime == Duration.zero ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sesi: ${activeSession!['class_name']}${activeSession!['subject'].toString().isNotEmpty ? ' - ${activeSession!['subject']}' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: remainingTime == Duration.zero ? Colors.red.shade800 : Colors.green.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: remainingTime == Duration.zero ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        remainingTime == Duration.zero
                            ? 'Waktu Absensi Habis'
                            : 'Sisa Waktu Absensi: ${_formatDuration(remainingTime)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: remainingTime == Duration.zero ? Colors.red : Colors.green.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tidak ada sesi absensi aktif dari mentor saat ini.',
                      style: TextStyle(color: Color(0xFF6B7280), height: 1.35, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB7185),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD1D5DB),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                isSubmitting ? 'Mengirim...' : 'Kirim Token',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
