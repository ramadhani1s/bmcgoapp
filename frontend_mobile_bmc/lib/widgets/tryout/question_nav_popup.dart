import 'package:flutter/material.dart';

class QuestionNavPopup extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final Set<int> flagged;
  const QuestionNavPopup({super.key, required this.questions, required this.flagged});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 320,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1),
            itemCount: questions.length,
            itemBuilder: (c, i) {
              final flaggedMark = flagged.contains(i);
              return GestureDetector(
                onTap: () => Navigator.pop(context, i),
                child: Container(
                  decoration: BoxDecoration(color: flaggedMark ? const Color(0xFFFFF0F0) : Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFECECEC))),
                  child: Center(child: Text('${questions[i]['nomor'] ?? i + 1}')),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
