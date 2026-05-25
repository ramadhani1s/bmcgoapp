import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/models/soal_model.dart';
import 'option_tile.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.number,
    required this.question,
    required this.selectedAnswer,
    required this.submitted,
    required this.onSelectAnswer,
    required this.accentColor,
    required this.borderColor,
  });

  final int number;
  final SoalModel question;
  final String? selectedAnswer;
  final bool submitted;
  final void Function(String questionId, String answerKey) onSelectAnswer;
  final Color accentColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final options = question.pilihan.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

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
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Soal Latihan',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.pertanyaan,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          for (final option in options) ...[
            OptionTile(
              choiceKey: option.key,
              text: option.value,
              selected: (selectedAnswer?.toUpperCase() ?? '') == option.key.toUpperCase(),
              submittedCorrect: submitted && (selectedAnswer?.toUpperCase() ?? '') == question.kunciJawaban.toUpperCase(),
              onTap: () => onSelectAnswer(question.id, option.key),
              accentColor: accentColor,
              borderColor: borderColor,
            ),
            const SizedBox(height: 8),
          ],
          if (submitted) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Text(
                (selectedAnswer?.toUpperCase() ?? '') == question.kunciJawaban.toUpperCase()
                    ? 'Benar'
                    : 'Salah, jawaban benar: ${question.kunciJawaban}',
                style: const TextStyle(
                  color: Color(0xFF166534),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
