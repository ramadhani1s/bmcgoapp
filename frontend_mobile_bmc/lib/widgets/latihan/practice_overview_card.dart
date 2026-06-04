import 'package:flutter/material.dart';

class PracticeOverviewCard extends StatelessWidget {
  final String subject;
  final int totalSoal;

  const PracticeOverviewCard({
    super.key,
    required this.subject,
    required this.totalSoal,
  });

  String _getSubjectDisplay() {
    final displays = {
      'Matematika': 'Matematika\nAljabar & Fungsi Kuadrat',
      'IPA': 'IPA\nIlmu Pengetahuan Alam',
      'IPS': 'IPS\nIlmu Pengetahuan Sosial',
      'B. Indo': 'B. Indonesia\nBahasa Indonesia',
      'B. Inggris': 'B. Inggris\nBahasa Inggris',
    };
    return displays[subject] ?? '$subject\nLatihan Soal';
  }

  @override
  Widget build(BuildContext context) {
    final subjectParts = _getSubjectDisplay().split('\n');
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B35), Color(0xFFFF8A5C)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subjectParts[0],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subjectParts[1],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kak Budi',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description, size: 12, color: Color(0xFFFF6B35)),
                        const SizedBox(width: 4),
                        Text(
                          '$totalSoal Halaman',
                          style: const TextStyle(
                            color: Color(0xFFFF6B35),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'PDF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}