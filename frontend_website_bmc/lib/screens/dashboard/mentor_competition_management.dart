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

// =============================================================================
// MentorCompetitionManagement
// =============================================================================

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
  // ── State ──────────────────────────────────────────────────────────────────

  bool _isLoading = true;
  List<MentorCompetitionItem> _items = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedClass = 'Semua Kelas';

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

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
      final keywordMatch =
          keyword.isEmpty || e.title.toLowerCase().contains(keyword);
      final classMatch =
          _selectedClass == 'Semua Kelas' || e.classLevel == _selectedClass;
      return keywordMatch && classMatch;
    }).toList();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _onSidebarMenuTap(String title) {
    switch (title) {
      case 'Dashboard':
        Navigator.pushReplacementNamed(context, AppRoutes.mentorDashboard);

      case 'Jadwal Mengajar':
        Navigator.pushReplacement(
          context,
          InstantPageRoute(
            child: const JadwalPembelajaranScreen(mentorView: true),
          ),
        );

      case 'Absensi Kelas':
        Navigator.pushReplacement(
          context,
          InstantPageRoute(child: const MentorAttendanceScreen()),
        );

      case 'Soal Latihan':
        Navigator.pushReplacementNamed(context, AppRoutes.mentorExercise);

      case 'Try Out':
        if (widget.type == 'tryout') return;
        Navigator.pushReplacementNamed(context, AppRoutes.mentorTryout);

      case 'Materi Pembelajaran':
        Navigator.pushReplacement(
          context,
          InstantPageRoute(
            child: const MateriPembelajaranScreen(initialClass: null),
          ),
        );

      case 'Olimpiade Akademik':
        if (widget.type == 'olimpiade') return;
        Navigator.pushReplacement(
          context,
          InstantPageRoute(child: const MentorOlimpiadeScreen()),
        );
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _openTryoutSoalManagement(MentorCompetitionItem tryout) async {
    await Navigator.of(
      context,
    ).push(InstantPageRoute(child: TryoutSoalManagementScreen(tryout: tryout)));
    if (mounted) await _load();
  }

  Future<void> _openOlimpiadeSoalManagement(
    MentorCompetitionItem olimpiade,
  ) async {
    await Navigator.of(context).push(
      InstantPageRoute(
        child: OlimpiadeSoalManagementScreen(olimpiade: olimpiade),
      ),
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
        title: const Text('Hapus data?'),
        content: Text('Yakin hapus ${item.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatScheduleLabel(String value) {
    final text = value.trim();
    if (text.isEmpty) return '-';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return text;
    final yyyy = parsed.year.toString().padLeft(4, '0');
    final mm = parsed.month.toString().padLeft(2, '0');
    final dd = parsed.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  int _publishedCount() => _items.where((item) => item.isPublished).length;

  int _totalQuestionsCount() =>
      _items.fold<int>(0, (sum, item) => sum + item.totalQuestions);

  int _classCount() => _items.map((item) => item.classLevel).toSet().length;

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildBadge(
    String label, {
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
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
    Color backgroundColor = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(child: Icon(icon, size: 18, color: iconColor)),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitionCard(MentorCompetitionItem item) {
    final scheduleLabel = _formatScheduleLabel(item.scheduleLabel);
    final progressValue = item.totalQuestions > 0
        ? (item.soalTerbuat / item.totalQuestions).clamp(0.0, 1.0)
        : 0.0;
    final progressPercent = (progressValue * 100).round();
    final isPublished = item.isPublished;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              _buildBadge(
                isPublished ? 'Dipublikasikan' : 'Draft',
                backgroundColor: isPublished
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEF3C7),
                foregroundColor: isPublished
                    ? const Color(0xFF065F46)
                    : const Color(0xFF92400E),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Meta chips ─────────────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                item.subject,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              _buildBadge(
                item.classLevel,
                backgroundColor: const Color(0xFFEFF6FF),
                foregroundColor: const Color(0xFF2563EB),
              ),
              Text(
                '${item.durationLabel} menit',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${item.soalTerbuat}/${item.totalQuestions} soal',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 14),

          // ── Info row ───────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildSmallInfo(
                  Icons.calendar_today_outlined,
                  scheduleLabel,
                ),
              ),
              Expanded(
                child: _buildSmallInfo(
                  Icons.timer_outlined,
                  '${item.durationLabel} mnt',
                ),
              ),
              Expanded(
                child: _buildSmallInfo(
                  Icons.assignment_outlined,
                  '${item.soalTerbuat}/${item.totalQuestions} soal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Progress ───────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress Soal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                '$progressPercent%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentBlue,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Action buttons ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () => widget.type == 'tryout'
                        ? _openTryoutSoalManagement(item)
                        : _openOlimpiadeSoalManagement(item),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Kelola Soal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildActionIconButton(
                icon: Icons.edit_outlined,
                iconColor: const Color(0xFF6B7280),
                borderColor: const Color(0xFFD1D5DB),
                onPressed: () => _openForm(item: item),
                tooltip: 'Edit',
              ),
              const SizedBox(width: 8),
              _buildActionIconButton(
                icon: Icons.delete_outline,
                iconColor: const Color(0xFFEF4444),
                borderColor: const Color(0xFFFECACA),
                onPressed: () => _deleteItem(item),
                tooltip: 'Hapus',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;
    final isTryout = widget.type == 'tryout';

    final pageTitle = isTryout ? 'Kelola Try Out' : 'Kelola Olimpiade Akademik';
    final pageSubtitle = isTryout
        ? 'Atur daftar try out, detail soal, dan jadwal publikasi secara konsisten.'
        : 'Atur daftar olimpiade, lokasi, tanggal, dan pengelolaan soal secara konsisten.';

    return MentorSidebarShell(
      activeMenuTitle: isTryout ? 'Try Out' : 'Olimpiade Akademik',
      onMenuTap: _onSidebarMenuTap,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroBanner(
                        pageTitle: pageTitle,
                        pageSubtitle: pageSubtitle,
                        isTryout: isTryout,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCards(
                        visibleItems: visibleItems,
                        isTryout: isTryout,
                      ),
                      const SizedBox(height: 20),
                      _buildFilterAndList(
                        visibleItems: visibleItems,
                        isTryout: isTryout,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeroBanner({
    required String pageTitle,
    required String pageSubtitle,
    required bool isTryout,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pageTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pageSubtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Icon(
            isTryout ? Icons.quiz_outlined : Icons.emoji_events_outlined,
            color: Colors.white,
            size: 64,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards({
    required List<MentorCompetitionItem> visibleItems,
    required bool isTryout,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 900) {
          final cardWidth = (width - (16 * 3)) / 4;
          return Row(
            children: [
              SizedBox(
                width: cardWidth,
                child: _buildInfoCard(
                  visibleItems.length.toString(),
                  isTryout ? 'Total Try Out' : 'Total Olimpiade',
                  Icons.view_list_outlined,
                  AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: cardWidth,
                child: _buildInfoCard(
                  _publishedCount().toString(),
                  'Sudah Publish',
                  Icons.check_circle_outline,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: cardWidth,
                child: _buildInfoCard(
                  _totalQuestionsCount().toString(),
                  'Total Soal',
                  Icons.help_outline,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: cardWidth,
                child: _buildInfoCard(
                  _classCount().toString(),
                  'Kelas',
                  Icons.class_outlined,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          );
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildInfoCard(
                  visibleItems.length.toString(),
                  isTryout ? 'Total Try Out' : 'Total Olimpiade',
                  Icons.view_list_outlined,
                  AppColors.accentBlue,
                ),
                const SizedBox(width: 16),
                _buildInfoCard(
                  _publishedCount().toString(),
                  'Sudah Publish',
                  Icons.check_circle_outline,
                  const Color(0xFF10B981),
                ),
                const SizedBox(width: 16),
                _buildInfoCard(
                  _totalQuestionsCount().toString(),
                  'Total Soal',
                  Icons.help_outline,
                  const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 16),
                _buildInfoCard(
                  _classCount().toString(),
                  'Kelas',
                  Icons.class_outlined,
                  const Color(0xFF8B5CF6),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildFilterAndList({
    required List<MentorCompetitionItem> visibleItems,
    required bool isTryout,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        InputDecoration inputDecoration({
          String? hintText,
          Widget? prefixIcon,
        }) {
          return InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            filled: true,
            isDense: true,
            fillColor: const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.5,
              ),
            ),
          );
        }

        final searchField = TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: inputDecoration(
            hintText: isTryout ? 'Cari try out...' : 'Cari olimpiade...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
          ),
        );

        final classField = DropdownButtonFormField<String>(
          value: _selectedClass,
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6B7280),
            size: 20,
          ),
          items:
              const [
                    'Semua Kelas',
                    'Kelas 10 IPA',
                    'Kelas 10 IPS',
                    'Kelas 11 IPA',
                    'Kelas 11 IPS',
                    'Kelas 12 IPA',
                    'Kelas 12 IPS',
                  ]
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
          onChanged: (value) =>
              setState(() => _selectedClass = value ?? 'Semua Kelas'),
          decoration: inputDecoration(
            prefixIcon: const Icon(
              Icons.class_outlined,
              size: 18,
              color: Color(0xFF2563EB),
            ),
          ),
        );

        final addButton = ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            isTryout ? 'Tambah Try Out' : 'Tambah Olimpiade',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            minimumSize: const Size(160, 48),
            maximumSize: const Size(200, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        );

        final filterRow = isWide
            ? Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 16),
                  SizedBox(width: 240, child: classField),
                  const SizedBox(width: 16),
                  addButton,
                ],
              )
            : Column(
                children: [
                  searchField,
                  const SizedBox(height: 10),
                  classField,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: addButton),
                ],
              );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              filterRow,
              const SizedBox(height: 24),
              if (visibleItems.isEmpty)
                _buildEmptyState(isTryout: isTryout)
              else
                _buildCardGrid(visibleItems),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({required bool isTryout}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDD5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFFF97316),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isTryout ? 'Belum Ada Try Out' : 'Belum Ada Olimpiade',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isTryout
                ? 'Belum ada data try out yang tersedia'
                : 'Belum ada data olimpiade yang tersedia',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrid(List<MentorCompetitionItem> items) {
    return LayoutBuilder(
      builder: (context, listConstraints) {
        final width = listConstraints.maxWidth;
        final columns = width >= 1500
            ? 4
            : (width >= 1100 ? 3 : (width >= 700 ? 2 : 1));
        final cardWidth = (width - ((columns - 1) * 20)) / columns;

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: items
              .map(
                (item) => SizedBox(
                  width: cardWidth,
                  child: _buildCompetitionCard(item),
                ),
              )
              .toList(),
        );
      },
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
  // ── State ──────────────────────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _subjectController;
  late TextEditingController _durationController;
  late TextEditingController _totalQuestionsController;
  late TextEditingController _scheduleController;

  String _selectedClass = 'Kelas 12 IPA';
  bool _isSubmitting = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _subjectController = TextEditingController(text: e?.subject ?? '');
    _durationController = TextEditingController(text: e?.durationLabel ?? '');
    _totalQuestionsController = TextEditingController(
      text: e?.totalQuestions.toString() ?? '0',
    );
    _scheduleController = TextEditingController(text: e?.scheduleLabel ?? '');
    _selectedClass = e?.classLevel ?? 'Kelas 12 IPA';
    if (_selectedClass == 'Kelas 10') _selectedClass = 'Kelas 10 IPA';
    if (_selectedClass == 'Kelas 11') _selectedClass = 'Kelas 11 IPA';
    if (_selectedClass == 'Kelas 12') _selectedClass = 'Kelas 12 IPA';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _durationController.dispose();
    _totalQuestionsController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    final totalQuestions = int.tryParse(_totalQuestionsController.text) ?? 0;
    final isOlimpiade = widget.type == 'olimpiade';

    print('========== SUBMIT DATA ==========');
    print('Type: ${widget.type}');
    print('Title: ${_titleController.text.trim()}');
    print('Subject/Lokasi: ${_subjectController.text.trim()}');
    print('Class Level: $_selectedClass');
    print('Schedule: ${_scheduleController.text.trim()}');
    print('Duration: ${_durationController.text.trim()}');
    print('Total Questions: $totalQuestions');
    print('==================================');
    try {
      final res = await MentorCompetitionService.createOrUpdate(
        type: widget.type,
        id: widget.existing?.id,
        classLevel: _selectedClass,
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim(),
        scheduleLabel: _scheduleController.text.trim(),
        durationLabel: _durationController.text.trim(),
        totalQuestions: totalQuestions,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Gagal menyimpan'),
          ),
        );
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      print('Error: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isOlimpiade = widget.type == 'olimpiade';

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    );

    InputDecoration _fieldDecoration({
      required String labelText,
      String? hintText,
    }) {
      return InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.16),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ───────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.existing == null
                              ? Icons.add
                              : Icons.edit_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.existing == null
                                  ? (isOlimpiade
                                        ? 'Tambah Olimpiade'
                                        : 'Tambah Try Out')
                                  : 'Edit',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isOlimpiade
                                  ? 'Form Olimpiade Akademik'
                                  : 'Form Try Out',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.3,
                              ),
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

                // ── Body ─────────────────────────────────────────────────────
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Isi detail kompetisi di bawah',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 1. Judul
                            TextFormField(
                              controller: _titleController,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Judul wajib diisi'
                                  : null,
                              decoration: _fieldDecoration(
                                labelText: isOlimpiade
                                    ? 'Judul Olimpiade'
                                    : 'Judul Try Out',
                                hintText: isOlimpiade
                                    ? 'Masukkan nama olimpiade (Contoh: Olimpiade Sains Nasional)'
                                    : 'Masukkan nama try out (Contoh: Try Out UTBK Sesi 1)',
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 2. Lokasi / Subjek
                            TextFormField(
                              controller: _subjectController,
                              validator: (v) =>
                                  isOlimpiade && (v == null || v.isEmpty)
                                  ? 'Lokasi wajib diisi'
                                  : null,
                              decoration: _fieldDecoration(
                                labelText: isOlimpiade ? 'Lokasi' : 'Subjek',
                                hintText: isOlimpiade
                                    ? 'Masukkan lokasi ujian (Contoh: Aula Utama Kampus)'
                                    : 'Masukkan mata pelajaran (Contoh: Matematika IPA)',
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 3. Kondisional: Olimpiade vs Try Out
                            if (isOlimpiade) ...[
                              // Tanggal
                              TextFormField(
                                controller: _scheduleController,
                                readOnly: true,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Tanggal wajib diisi'
                                    : null,
                                onTap: () async {
                                  final now = DateTime.now();
                                  DateTime initial = now;
                                  final parsed = DateTime.tryParse(
                                    _scheduleController.text,
                                  );
                                  if (parsed != null) initial = parsed;
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: initial,
                                    firstDate: DateTime(now.year - 5),
                                    lastDate: DateTime(now.year + 5),
                                  );
                                  if (picked != null) {
                                    final yyyy = picked.year.toString().padLeft(
                                      4,
                                      '0',
                                    );
                                    final mm = picked.month.toString().padLeft(
                                      2,
                                      '0',
                                    );
                                    final dd = picked.day.toString().padLeft(
                                      2,
                                      '0',
                                    );
                                    _scheduleController.text = '$yyyy-$mm-$dd';
                                  }
                                },
                                decoration: _fieldDecoration(
                                  labelText: 'Tanggal Olimpiade',
                                  hintText:
                                      'Pilih tanggal pelaksanaan kompetisi',
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Total Soal (olimpiade)
                              TextFormField(
                                controller: _totalQuestionsController,
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Total soal wajib diisi'
                                    : null,
                                decoration: _fieldDecoration(
                                  labelText: 'Total Soal',
                                  hintText:
                                      'Masukkan jumlah butir soal (Contoh: 40)',
                                ),
                              ),
                              const SizedBox(height: 10),
                            ] else ...[
                              // Durasi (tryout)
                              TextFormField(
                                controller: _durationController,
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Durasi wajib diisi'
                                    : null,
                                decoration: _fieldDecoration(
                                  labelText: 'Durasi (menit)',
                                  hintText:
                                      'Masukkan durasi waktu (Contoh: 90)',
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Total Soal (tryout)
                              TextFormField(
                                controller: _totalQuestionsController,
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Total soal wajib diisi'
                                    : null,
                                decoration: _fieldDecoration(
                                  labelText: 'Total Soal',
                                  hintText:
                                      'Masukkan jumlah butir soal (Contoh: 40)',
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            // 4. Dropdown Kelas
                            DropdownButtonFormField<String>(
                              value: _selectedClass,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF6B7280),
                                size: 20,
                              ),
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                              ),
                              items:
                                  const [
                                        'Kelas 10 IPA',
                                        'Kelas 10 IPS',
                                        'Kelas 11 IPA',
                                        'Kelas 11 IPS',
                                        'Kelas 12 IPA',
                                        'Kelas 12 IPS',
                                      ]
                                      .map(
                                        (c) => DropdownMenuItem<String>(
                                          value: c,
                                          child: Text(c),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => setState(
                                () => _selectedClass = v ?? _selectedClass,
                              ),
                              decoration: _fieldDecoration(labelText: 'Kelas'),
                            ),
                            const SizedBox(height: 24),

                            // Tombol Batal & Simpan
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isSubmitting
                                        ? null
                                        : () =>
                                              Navigator.of(context).pop(false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF64748B),
                                      side: const BorderSide(
                                        color: Color(0xFFD8E1EE),
                                      ),
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
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
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Simpan'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
