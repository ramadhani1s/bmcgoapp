import 'package:flutter/material.dart';

class SubjectFilter extends StatelessWidget {
  const SubjectFilter({
    super.key,
    required this.subjects,
    required this.selected,
    required this.onTap,
    required this.accentColor,
    required this.mutedColor,
  });

  final List<String> subjects;
  final String selected;
  final void Function(String) onTap;
  final Color accentColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: subjects.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final subject = subjects[index];
            final isSelected = selected == subject;
            return GestureDetector(
              onTap: () => onTap(subject),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? accentColor : const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  subject,
                  style: TextStyle(
                    color: isSelected ? Colors.white : mutedColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
