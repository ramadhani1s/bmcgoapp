import 'package:flutter/material.dart';

class NavigationButtonRow extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isPreviousEnabled;
  final bool isNextEnabled;
  final bool isLastQuestion;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const NavigationButtonRow({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.isPreviousEnabled,
    required this.isNextEnabled,
    required this.isLastQuestion,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (isLastQuestion && !isSubmitting) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isPreviousEnabled ? onPrevious : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(
                  color: isPreviousEnabled 
                      ? const Color(0xFF007AFF) 
                      : const Color(0xFFE5E5EA),
                ),
              ),
              child: Text(
                '← Sebelumnya',
                style: TextStyle(
                  color: isPreviousEnabled 
                      ? const Color(0xFF007AFF) 
                      : const Color(0xFF8E8E93),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isPreviousEnabled ? onPrevious : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(
                color: isPreviousEnabled 
                    ? const Color(0xFF007AFF) 
                    : const Color(0xFFE5E5EA),
              ),
            ),
            child: Text(
              '← Sebelumnya',
              style: TextStyle(
                color: isPreviousEnabled 
                    ? const Color(0xFF007AFF) 
                    : const Color(0xFF8E8E93),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: isNextEnabled ? onNext : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(
                color: isNextEnabled 
                    ? const Color(0xFF007AFF) 
                    : const Color(0xFFE5E5EA),
              ),
            ),
            child: Text(
              'Berikutnya →',
              style: TextStyle(
                color: isNextEnabled 
                    ? const Color(0xFF007AFF) 
                    : const Color(0xFF8E8E93),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
