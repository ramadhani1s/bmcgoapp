import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../dashboard/mentor_competition_management.dart';

class MentorTryoutManagementScreen extends StatelessWidget {
  const MentorTryoutManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MentorCompetitionManagement(
      type: 'tryout',
      title: 'Kelola Try Out',
      subtitle: 'Buat dan kelola try out untuk siswa',
      accentColor: AppColors.accentBlue,
    );
  }
}
