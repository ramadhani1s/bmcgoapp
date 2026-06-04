import 'package:flutter/material.dart';

class SoalCard extends StatelessWidget {
  final int currentSoal;
  final int totalSoal;
  final String soalText;
  final List<String> options;
  final String? selectedAnswer;
  final bool isSubmitted;
  final String? correctAnswer;
  final String pembahasan;
  final Function(String) onAnswerSelected;
  final VoidCallback onTogglePembahasan;
  final bool showPembahasan;

  const SoalCard({
    super.key,
    required this.currentSoal,
    required this.totalSoal,
    required this.soalText,
    required this.options,
    required this.selectedAnswer,
    required this.isSubmitted,
    this.correctAnswer,
    required this.pembahasan,
    required this.onAnswerSelected,
    required this.onTogglePembahasan,
    required this.showPembahasan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E5EA), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header "Soal 2 dari 5" seperti di gambar
            Text(
              'Soal $currentSoal dari $totalSoal',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            // Soal text - support LaTeX style
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                soalText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1C1C1E),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Options (A, B, C, D)
            ...List.generate(options.length, (index) {
              final letter = String.fromCharCode(65 + index); // A, B, C, D
              final isSelected = selectedAnswer == letter;
              final isCorrect = !isSubmitted ? false : correctAnswer == letter;
              final isWrongSelected = isSubmitted && isSelected && !isCorrect;
              
              return _buildOptionTile(
                letter: letter,
                text: options[index],
                isSelected: isSelected,
                isCorrect: isCorrect,
                isWrongSelected: isWrongSelected,
                isSubmitted: isSubmitted,
                onTap: () => onAnswerSelected(letter),
              );
            }),
            
            const SizedBox(height: 24),
            
            // Pembahasan section (hanya muncul jika sudah dijawab / disubmit)
            if (isSubmitted) ...[
              GestureDetector(
                onTap: onTogglePembahasan,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pembahasan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF007AFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        showPembahasan 
                            ? Icons.keyboard_arrow_up 
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF8E8E93),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Pembahasan content
              if (showPembahasan)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pembahasan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pembahasan,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1C1C1E),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String letter,
    required String text,
    required bool isSelected,
    required bool isCorrect,
    required bool isWrongSelected,
    required bool isSubmitted,
    required VoidCallback onTap,
  }) {
    Color getBackgroundColor() {
      if (!isSubmitted) {
        return isSelected ? const Color(0xFFE3F2FD) : Colors.white;
      }
      if (isCorrect) return const Color(0xFFE8F5E9);
      if (isWrongSelected) return const Color(0xFFFFEBEE);
      return Colors.white;
    }

    Color getBorderColor() {
      if (!isSubmitted) {
        return isSelected ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA);
      }
      if (isCorrect) return const Color(0xFF4CAF50);
      if (isWrongSelected) return const Color(0xFFF44336);
      return const Color(0xFFE5E5EA);
    }

    Color getLetterColor() {
      if (!isSubmitted) {
        return isSelected ? const Color(0xFF007AFF) : const Color(0xFF8E8E93);
      }
      if (isCorrect) return const Color(0xFF4CAF50);
      if (isWrongSelected) return const Color(0xFFF44336);
      return const Color(0xFF8E8E93);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: getBackgroundColor(),
          border: Border.all(color: getBorderColor(), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: getLetterColor().withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: getLetterColor(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ),
            if (isSubmitted && isCorrect)
              const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
            if (isSubmitted && isWrongSelected)
              const Icon(Icons.cancel, color: Color(0xFFF44336), size: 20),
          ],
        ),
      ),
    );
  }
}
