import 'package:flutter/material.dart';

class SubmitCard extends StatelessWidget {
  const SubmitCard({
    super.key,
    required this.submitted,
    required this.isSubmitting,
    required this.score,
    required this.questionsLength,
    required this.onSubmit,
    required this.onRetry,
    required this.accentColor,
    required this.borderColor,
  });

  final bool submitted;
  final bool isSubmitting;
  final int score;
  final int questionsLength;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;
  final Color accentColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            submitted ? 'Hasil Latihan' : 'Selesaikan Latihan',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            submitted ? 'Skor kamu: $score dari $questionsLength' : 'Pastikan semua soal sudah dijawab sebelum dikirim.',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitted || isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(submitted ? 'Sudah Dikirim' : 'Kirim Jawaban'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: borderColor),
              foregroundColor: const Color(0xFF111827),
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Ulangi Latihan'),
          ),
        ],
      ),
    );
  }
}
