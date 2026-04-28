import 'package:flutter/material.dart';

import 'mentor_competition_management.dart';

class MentorOlimpiadeScreen extends StatelessWidget {
  const MentorOlimpiadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MentorCompetitionManagement(
      type: 'olimpiade',
      title: 'Kelola Olimpiade Akademik',
      subtitle: 'Buat dan kelola event olimpiade akademik untuk siswa',
      accentColor: Color(0xFFFB5607),
    );
  }
}
