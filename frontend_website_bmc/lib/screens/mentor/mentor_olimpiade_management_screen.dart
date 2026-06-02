import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../dashboard/mentor_competition_management.dart';

class MentorOlimpiadeManagementScreen extends StatelessWidget {
  const MentorOlimpiadeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MentorCompetitionManagement(
      type: 'olimpiade',
      title: 'Kelola Olimpiade Akademik',
      subtitle: 'Buat dan kelola event olimpiade akademik untuk siswa',
      accentColor: AppColors.accentBlue,
    );
  }
}
