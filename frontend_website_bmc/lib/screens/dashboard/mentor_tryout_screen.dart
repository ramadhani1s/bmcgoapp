import 'package:flutter/material.dart';

import 'mentor_competition_management.dart';

class MentorTryoutScreen extends StatelessWidget {
  const MentorTryoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MentorCompetitionManagement(
      type: 'tryout',
      title: 'Kelola Try Out',
      subtitle: 'Buat dan kelola try out untuk siswa',
      accentColor: Color(0xFF2563EB),
    );
  }
}
