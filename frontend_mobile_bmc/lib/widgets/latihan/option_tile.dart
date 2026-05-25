import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.choiceKey,
    required this.text,
    required this.selected,
    required this.submittedCorrect,
    required this.onTap,
    required this.accentColor,
    required this.borderColor,
  });

  final String choiceKey;
  final String text;
  final bool selected;
  final bool submittedCorrect;
  final VoidCallback onTap;
  final Color accentColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accentColor : borderColor,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? accentColor : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                choiceKey,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ),
            if (submittedCorrect)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF16A34A),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
