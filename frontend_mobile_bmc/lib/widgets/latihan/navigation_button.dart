import 'package:flutter/material.dart';

class NavigationButtons extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final bool isSubmitting;
  final bool isSubmitted;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const NavigationButtons({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.isSubmitting,
    required this.isSubmitted,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (isSubmitted) {
      return Row(
        children: [
          Expanded(
            child: _buildPreviousButton(isActive: currentIndex > 0),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildNextButton(isActive: currentIndex < totalQuestions - 1),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildPreviousButton(isActive: currentIndex > 0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSubmitOrNextButton(),
        ),
      ],
    );
  }

  Widget _buildPreviousButton({required bool isActive}) {
    return OutlinedButton(
      onPressed: isActive ? onPrevious : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: isActive ? const Color(0xFFFF6B35) : const Color(0xFFE8E8ED),
        ),
      ),
      child: Text(
        '← Sebelumnya',
        style: TextStyle(
          color: isActive ? const Color(0xFFFF6B35) : const Color(0xFF8D90A3),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildNextButton({required bool isActive}) {
    return OutlinedButton(
      onPressed: isActive ? onNext : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: isActive ? const Color(0xFFFF6B35) : const Color(0xFFE8E8ED),
        ),
      ),
      child: Text(
        'Berikutnya →',
        style: TextStyle(
          color: isActive ? const Color(0xFFFF6B35) : const Color(0xFF8D90A3),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSubmitOrNextButton() {
    final isLastQuestion = currentIndex == totalQuestions - 1;
    
    return ElevatedButton(
      onPressed: isSubmitting
          ? null
          : (isLastQuestion ? onSubmit : onNext),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B35),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        isSubmitting
            ? 'Mengirim...'
            : (isLastQuestion ? 'Selesai' : 'Berikutnya →'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}