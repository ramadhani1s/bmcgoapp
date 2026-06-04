import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  final String optionKey; // A, B, C, D
  final String optionValue;
  final bool isSelected;
  final bool isSubmitted;
  final String? correctAnswer;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.optionKey,
    required this.optionValue,
    required this.isSelected,
    required this.isSubmitted,
    this.correctAnswer,
    required this.onTap,
  });

  Color _getBackgroundColor() {
    if (!isSubmitted) {
      return isSelected ? const Color(0xFFFFF0EB) : Colors.white;
    }
    
    final isCorrect = correctAnswer == optionKey;
    if (isCorrect) return const Color(0xFFE8F5E9);
    if (isSelected && !isCorrect) return const Color(0xFFFFEBEE);
    return Colors.white;
  }

  Color _getBorderColor() {
    if (!isSubmitted) {
      return isSelected ? const Color(0xFFFF6B35) : const Color(0xFFE8E8ED);
    }
    
    final isCorrect = correctAnswer == optionKey;
    if (isCorrect) return const Color(0xFF4CAF50);
    if (isSelected && !isCorrect) return const Color(0xFFF44336);
    return const Color(0xFFE8E8ED);
  }

  Color _getIconColor() {
    if (!isSubmitted) {
      return isSelected ? Colors.white : const Color(0xFF8D90A3);
    }
    
    final isCorrect = correctAnswer == optionKey;
    if (isCorrect) return Colors.white;
    if (isSelected && !isCorrect) return Colors.white;
    return const Color(0xFF8D90A3);
  }

  Color _getBoxColor() {
    if (!isSubmitted) {
      return isSelected ? const Color(0xFFFF6B35) : Colors.white;
    }
    
    final isCorrect = correctAnswer == optionKey;
    if (isCorrect) return const Color(0xFF4CAF50);
    if (isSelected && !isCorrect) return const Color(0xFFF44336);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          border: Border.all(color: _getBorderColor(), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _getBoxColor(),
                border: Border.all(color: _getBorderColor()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: _buildIcon(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                optionValue,
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isSubmitted && correctAnswer == optionKey)
              const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
            if (isSubmitted && isSelected && correctAnswer != optionKey)
              const Icon(Icons.cancel, color: Color(0xFFF44336), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (!isSubmitted) {
      return Text(
        optionKey,
        style: TextStyle(
          color: _getIconColor(),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      );
    }
    
    final isCorrect = correctAnswer == optionKey;
    if (isCorrect) {
      return const Icon(Icons.check, color: Colors.white, size: 16);
    }
    if (isSelected && !isCorrect) {
      return const Icon(Icons.close, color: Colors.white, size: 16);
    }
    return Text(
      optionKey,
      style: const TextStyle(
        color: Color(0xFF8D90A3),
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }
}