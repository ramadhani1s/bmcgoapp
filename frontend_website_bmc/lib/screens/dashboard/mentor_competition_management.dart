import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../models/mentor_competition_item.dart';
import '../../services/mentor_competition_service.dart';
import '../dashboard/jadwal_pembelajaran_screen.dart';
import '../dashboard/mentor_attendance_screen.dart';
import '../dashboard/mentor_olimpiade_screen.dart';
import '../mentor/materi_pembelajaran_screen.dart';
import '../mentor/tryout_soal_management_screen.dart';
import '../mentor/olimpiade_soal_management_screen.dart';
import '../../widgets/mentor_sidebar_shell.dart';

class MentorCompetitionManagement extends StatefulWidget {
  final String type;
  final String title;
  final String subtitle;
  final Color accentColor;

  const MentorCompetitionManagement({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  State<MentorCompetitionManagement> createState() =>
      _MentorCompetitionManagementState();
}

class _MentorCompetitionManagementState
    extends State<MentorCompetitionManagement> {
  bool _isLoading = true;
  List<MentorCompetitionItem> _items = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedClass = 'Semua Kelas';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await MentorCompetitionService.getByType(widget.type);
      if (mounted) setState(() => _items = data);
    } catch (_) {
      if (mounted) setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<MentorCompetitionItem> get _visibleItems {
    final keyword = _searchController.text.trim().toLowerCase();
    return _items.where((e) {
      final keywordMatch = keyword.isEmpty || e.title.toLowerCase().contains(keyword);
      final classMatch = _selectedClass == 'Semua Kelas' || e.classLevel == _selectedClass;
      return keywordMatch && classMatch;
    }).toList();
  }

  void _onSidebarMenuTap(String title) {
    switch (title) {
      case 'Dashboard':
        Navigator.pushReplacementNamed(context, AppRoutes.mentorDashboard);
        break;
      case 'Jadwal Mengajar':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const JadwalPembelajaranScreen(mentorView: true)),
        );
        break;
      case 'Absensi Kelas':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MentorAttendanceScreen()),
        );
        break;
      case 'Soal Latihan':
        Navigator.pushReplacementNamed(context, AppRoutes.mentorExercise);
        break;
      case 'Try Out':
        if (widget.type == 'tryout') return;
        Navigator.pushReplacementNamed(context, AppRoutes.mentorTryout);
        break;
      case 'Materi Pembelajaran':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MateriPembelajaranScreen(initialClass: null)),
        );
        break;
      case 'Olimpiade Akademik':
        if (widget.type == 'olimpiade') return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MentorOlimpiadeScreen()),
        );
        break;
    }
  }

  Future<void> _openTryoutSoalManagement(MentorCompetitionItem tryout) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TryoutSoalManagementScreen(tryout: tryout)),
    );
    if (mounted) await _load();
  }

  Future<void> _openOlimpiadeSoalManagement(MentorCompetitionItem olimpiade) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OlimpiadeSoalManagementScreen(olimpiade: olimpiade)),
    );
    if (mounted) await _load();
  }

  Future<void> _openForm({MentorCompetitionItem? item}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CompetitionFormDialog(
        parentContext: context,
        existing: item,
        type: widget.type,
        accentColor: widget.accentColor,
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _deleteItem(MentorCompetitionItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: Text(
          widget.type == 'tryout' ? 'Hapus Try Out?' : 'Hapus Olimpiade?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin menghapus "${item.title}"?',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.warning, color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aksi ini tidak bisa dibatalkan. Semua data nilai dan soal di dalamnya akan dihapus secara permanen dari sistem.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4B5563),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await MentorCompetitionService.deleteById(widget.type, item.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message']?.toString() ?? 'Selesai')),
    );

    if (res['success'] == true) await _load();
  }

  String _formatScheduleLabel(String value) {
    final text = value.trim();
    if (text.isEmpty) return '-';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return text;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  int _publishedCount() => _items.where((item) => item.isPublished).length;
  int _totalQuestionsCount() => _items.fold<int>(0, (sum, item) => sum + item.totalQuestions);
  int _classCount() => _items.map((item) => item.classLevel).toSet().length;

  Widget _buildBadge(String label, {required Color backgroundColor, required Color foregroundColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 12, color: foregroundColor, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSmallInfo(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Center(child: Icon(icon, size: 18, color: iconColor)),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String value, String label, IconData icon, Color color) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;
    final isTryout = widget.type == 'tryout';

    return MentorSidebarShell(
      activeMenuTitle: isTryout ? 'Try Out' : 'Olimpiade Akademik',
      onMenuTap: _onSidebarMenuTap,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroBanner(isTryout: isTryout),
                    const SizedBox(height: 20),
                    _buildInfoCards(visibleItems: visibleItems, isTryout: isTryout),
                    const SizedBox(height: 20),
                    _buildFilterAndList(visibleItems: visibleItems, isTryout: isTryout),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeroBanner({required bool isTryout}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTryout ? 'Kelola Try Out' : 'Kelola Olimpiade Akademik',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  isTryout
                      ? 'Atur daftar try out, detail soal, dan jadwal publikasi secara konsisten.'
                      : 'Atur daftar olimpiade, lokasi, tanggal, dan pengelolaan soal secara konsisten.',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Icon(isTryout ? Icons.quiz_outlined : Icons.emoji_events_outlined, color: Colors.white, size: 64),
        ],
      ),
    );
  }

  Widget _buildInfoCards({required List<MentorCompetitionItem> visibleItems, required bool isTryout}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildInfoCard(visibleItems.length.toString(), isTryout ? 'Total Try Out' : 'Total Olimpiade', Icons.view_list_outlined, AppColors.accentBlue),
          const SizedBox(width: 16),
          _buildInfoCard(_publishedCount().toString(), 'Sudah Publish', Icons.check_circle_outline, const Color(0xFF10B981)),
          const SizedBox(width: 16),
          _buildInfoCard(_totalQuestionsCount().toString(), 'Total Soal', Icons.help_outline, const Color(0xFFF59E0B)),
          const SizedBox(width: 16),
          _buildInfoCard(_classCount().toString(), 'Kelas', Icons.class_outlined, const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildFilterAndList({required List<MentorCompetitionItem> visibleItems, required bool isTryout}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: isTryout ? 'Cari try out...' : 'Cari olimpiade...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 200,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: PopupMenuButton<String>(
                    tooltip: '',
                    offset: const Offset(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    onSelected: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedClass = val;
                        });
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return const [
                        'Semua Kelas',
                        'Kelas 10 IPA',
                        'Kelas 10 IPS',
                        'Kelas 11 IPA',
                        'Kelas 11 IPS',
                        'Kelas 12 IPA',
                        'Kelas 12 IPS'
                      ].map((c) {
                        return PopupMenuItem<String>(
                          value: c,
                          height: 38,
                          child: Text(
                            c,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(
                            Icons.class_outlined,
                            size: 18,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedClass,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF374151),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF6B7280),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(isTryout ? 'Tambah Try Out' : 'Tambah Olimpiade'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (visibleItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.description_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(isTryout ? 'Belum Ada Try Out' : 'Belum Ada Olimpiade', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(isTryout ? 'Belum ada data try out yang tersedia' : 'Belum ada data olimpiade yang tersedia', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: visibleItems.map((item) => _buildCompetitionCard(item)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCompetitionCard(MentorCompetitionItem item) {
    final scheduleLabel = _formatScheduleLabel(item.scheduleLabel);
    final progressValue = item.totalQuestions > 0 ? (item.soalTerbuat / item.totalQuestions).clamp(0.0, 1.0) : 0.0;
    final progressPercent = (progressValue * 100).round();
    final isPublished = item.isPublished;

    print('===== CARD DATA =====');
    print('Title: ${item.title}');
    print('Class: ${item.classLevel}');
    print('=====================');

    return Container(
      width: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 10),
              _buildBadge(
                isPublished ? 'Dipublikasikan' : 'Draft',
                backgroundColor: isPublished ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                foregroundColor: isPublished ? const Color(0xFF065F46) : const Color(0xFF92400E),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge(
                item.classLevel,
                backgroundColor: const Color(0xFFEFF6FF),
                foregroundColor: const Color(0xFF2563EB),
              ),
              Text(
                '${item.durationLabel} menit',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              Text(
                '${item.soalTerbuat}/${item.totalQuestions} soal',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          Row(
            children: [
              Expanded(child: _buildSmallInfo(Icons.calendar_today_outlined, scheduleLabel)),
              Expanded(child: _buildSmallInfo(Icons.timer_outlined, '${item.durationLabel} mnt')),
              Expanded(child: _buildSmallInfo(Icons.assignment_outlined, '${item.soalTerbuat}/${item.totalQuestions} soal')),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress Soal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text('$progressPercent%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.type == 'tryout' ? _openTryoutSoalManagement(item) : _openOlimpiadeSoalManagement(item),
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: const Text('Kelola Soal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildActionIconButton(icon: Icons.edit_outlined, iconColor: const Color(0xFF6B7280), borderColor: const Color(0xFFD1D5DB), onPressed: () => _openForm(item: item), tooltip: 'Edit'),
              const SizedBox(width: 8),
              _buildActionIconButton(icon: Icons.delete_outline, iconColor: const Color(0xFFEF4444), borderColor: const Color(0xFFFECACA), onPressed: () => _deleteItem(item), tooltip: 'Hapus'),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _CompetitionFormDialog
// =============================================================================

class _CompetitionFormDialog extends StatefulWidget {
  final BuildContext parentContext;
  final MentorCompetitionItem? existing;
  final String type;
  final Color accentColor;

  const _CompetitionFormDialog({
    required this.parentContext,
    this.existing,
    required this.type,
    required this.accentColor,
  });

  @override
  State<_CompetitionFormDialog> createState() => _CompetitionFormDialogState();
}

class _CompetitionFormDialogState extends State<_CompetitionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _durationController;
  late TextEditingController _totalQuestionsController;
  late TextEditingController _scheduleController;

  String _selectedClass = 'Kelas 12 IPA';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _durationController = TextEditingController(text: e?.durationLabel ?? '');
    _totalQuestionsController = TextEditingController(text: e?.totalQuestions.toString() ?? '0');
    _scheduleController = TextEditingController(text: e?.scheduleLabel ?? '');
    _selectedClass = e?.classLevel ?? 'Kelas 12 IPA';
    if (_selectedClass == 'Kelas 10') _selectedClass = 'Kelas 10 IPA';
    if (_selectedClass == 'Kelas 11') _selectedClass = 'Kelas 11 IPA';
    if (_selectedClass == 'Kelas 12') _selectedClass = 'Kelas 12 IPA';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _totalQuestionsController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    print('===== SUBMIT DATA =====');
    print('Title: ${_titleController.text.trim()}');
    print('Schedule: ${_scheduleController.text.trim()}');
    print('Duration: ${_durationController.text.trim()}');
    print('Total Questions: ${_totalQuestionsController.text.trim()}');
    print('Class: $_selectedClass');
    print('=======================');
    
    setState(() => _isSubmitting = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    final totalQuestions = int.tryParse(_totalQuestionsController.text) ?? 0;

    try {
      final res = await MentorCompetitionService.createOrUpdate(
        type: widget.type,
        id: widget.existing?.id,
        classLevel: _selectedClass,
        title: _titleController.text.trim(),
        scheduleLabel: _scheduleController.text.trim(),
        durationLabel: _durationController.text.trim(),
        totalQuestions: totalQuestions,
      );

      if (!mounted) return;

      print('Response: $res');

      if (res['success'] == true) {
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? 'Gagal menyimpan'), backgroundColor: Colors.red),
        );
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      print('Error: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildFormDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required List<String> labels,
    required void Function(T) onChanged,
    String? hint,
  }) {
    String displayLabel = hint ?? 'Pilih $label';
    if (value != null) {
      final idx = items.indexOf(value);
      if (idx >= 0 && idx < labels.length) {
        displayLabel = labels[idx];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: PopupMenuButton<T>(
              tooltip: '',
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              onSelected: onChanged,
              itemBuilder: (BuildContext context) {
                return List.generate(items.length, (index) {
                  return PopupMenuItem<T>(
                    value: items[index],
                    height: 38,
                    child: Text(
                      labels[index],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  );
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOlimpiade = widget.type == 'olimpiade';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(15, 23, 42, 0.16), blurRadius: 24, offset: Offset(0, 14))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(12)),
                    child: Icon(widget.existing == null ? Icons.add : Icons.edit_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existing == null ? (isOlimpiade ? 'Tambah Olimpiade' : 'Tambah Try Out') : 'Edit',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isOlimpiade ? 'Form Olimpiade Akademik' : 'Form Try Out',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Body Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Isi detail kompetisi di bawah',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 14),
                    // Judul
                    TextFormField(
                      controller: _titleController,
                      validator: (v) => v == null || v.isEmpty ? 'Judul wajib diisi' : null,
                      decoration: InputDecoration(
                        labelText: isOlimpiade ? 'Judul Olimpiade' : 'Judul Try Out',
                        hintText: isOlimpiade ? 'Masukkan nama olimpiade' : 'Masukkan nama try out',
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tanggal
                    TextFormField(
                      controller: _scheduleController,
                      readOnly: true,
                      validator: (v) => v == null || v.isEmpty ? 'Tanggal wajib diisi' : null,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          _scheduleController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        }
                      },
                      decoration: InputDecoration(
                        labelText: isOlimpiade ? 'Tanggal Olimpiade' : 'Tanggal Pelaksanaan',
                        hintText: 'Pilih tanggal pelaksanaan',
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Durasi
                    TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Durasi wajib diisi' : null,
                      decoration: InputDecoration(
                        labelText: 'Durasi (menit)',
                        hintText: 'Masukkan durasi waktu',
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Total Soal
                    TextFormField(
                      controller: _totalQuestionsController,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Total soal wajib diisi' : null,
                      decoration: InputDecoration(
                        labelText: 'Total Soal',
                        hintText: 'Masukkan jumlah butir soal',
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Kelas
                    _buildFormDropdown<String>(
                      label: 'Kelas',
                      value: _selectedClass,
                      items: const [
                        'Kelas 10 IPA',
                        'Kelas 10 IPS',
                        'Kelas 11 IPA',
                        'Kelas 11 IPS',
                        'Kelas 12 IPA',
                        'Kelas 12 IPS'
                      ],
                      labels: const [
                        'Kelas 10 IPA',
                        'Kelas 10 IPS',
                        'Kelas 11 IPA',
                        'Kelas 11 IPS',
                        'Kelas 12 IPA',
                        'Kelas 12 IPS'
                      ],
                      onChanged: (value) => setState(() => _selectedClass = value),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD8E1EE)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentBlue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}