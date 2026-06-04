import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../models/soal_latihan.dart';
import '../dashboard/jadwal_pembelajaran_screen.dart';
import '../dashboard/mentor_attendance_screen.dart';
import '../dashboard/mentor_olimpiade_screen.dart';
import '../mentor/materi_pembelajaran_screen.dart';
import '../../services/latihan_soal_service.dart';
// removed unused import
import '../../widgets/mentor_sidebar_shell.dart';
import 'create_latihan_screen.dart';
import 'mengelola_soal_screen.dart';
import '../../models/materi_pembelajaran.dart';

class LatihanSoalScreen extends StatefulWidget {
  final MateriPembelajaran? materi;
  const LatihanSoalScreen({super.key, this.materi});

  @override
  State<LatihanSoalScreen> createState() => _LatihanSoalScreenState();
}

class _LatihanSoalScreenState extends State<LatihanSoalScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showForm = false;
  List<SoalLatihan> _items = const [];
  SoalLatihan? _editingItem;
  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _jumlahSoalController = TextEditingController(
    text: '1',
  );
  final TextEditingController _durasiController = TextEditingController();
  final TextEditingController _jadwalController = TextEditingController();
  final List<_QuestionDraft> _drafts = <_QuestionDraft>[];

  final List<String> _mapelOptions = const [
    'Matematika',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'Fisika',
    'Kimia',
    'Biologi',
    'Sosiologi',
    'Ekonomi',
    'Geografi',
  ];

  String _selectedMapel = 'Matematika';
  final String _selectedStatusFilter = '';
  final String _selectedMapelFilter = '';
  String _selectedClass = 'Semua Kelas';
  final List<String> _classOptions = const [
    'Semua Kelas',
    '10 IPA IPS',
    '11 IPA IPS',
    '12 IPA IPS',
  ];

  static const Color _primaryBlue = Color(0xFF2563EB);

  Future<void> _pickJadwalDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_jadwalController.text.trim()) ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null) {
      return;
    }

    final yyyy = selected.year.toString().padLeft(4, '0');
    final mm = selected.month.toString().padLeft(2, '0');
    final dd = selected.day.toString().padLeft(2, '0');
    _jadwalController.text = '$yyyy-$mm-$dd';
  }

  @override
  void initState() {
    super.initState();
    if (widget.materi != null) {
      _selectedMapel = _mapelOptions.contains(widget.materi!.subject)
          ? widget.materi!.subject
          : _mapelOptions.first;
      _selectedClass = _classOptions.contains(widget.materi!.classLevel)
          ? widget.materi!.classLevel
          : 'Semua Kelas';
    }
    _loadItems();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _jumlahSoalController.dispose();
    _durasiController.dispose();
    _jadwalController.dispose();
    _searchController.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    final items = await LatihanSoalService.getSoalLatihan();

    if (!mounted) {
      return;
    }

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  void _onSidebarMenuTap(String title) {
    if (title == 'Dashboard') {
      Navigator.pushReplacementNamed(context, AppRoutes.mentorDashboard);
      return;
    }
    if (title == 'Jadwal Mengajar') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const JadwalPembelajaranScreen(mentorView: true),
        ),
      );
      return;
    }
    if (title == 'Absensi Kelas') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MentorAttendanceScreen()),
      );
      return;
    }
    if (title == 'Soal Latihan') {
      return;
    }
    if (title == 'Try Out') {
      Navigator.pushNamed(context, AppRoutes.mentorTryout);
      return;
    }
    if (title == 'Materi Pembelajaran') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MateriPembelajaranScreen(initialClass: null),
        ),
      );
      return;
    }
    if (title == 'Olimpiade Akademik') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MentorOlimpiadeScreen()),
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _openCreateForm() async {
    final result = await Navigator.push<bool?>(
      context,
      PageRouteBuilder<bool?>(
        opaque: false,
        pageBuilder: (ctx, animation, secondaryAnimation) =>
            CreateLatihanScreen(
              mapel: _selectedMapel,
              materiId: widget.materi?.id,
            ),
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );

    if (result == true) {
      await _loadItems();
      _showMessage('Latihan dan soal berhasil ditambahkan');
    }
  }

  void _openEditForm(SoalLatihan item) {
    final parsed = _parseStoredQuestion(item.pertanyaan);

    _syncDraftCount(1);
    final draft = _drafts.first;
    draft.questionController.text = parsed.questionText;
    draft.optionAController.text = item.pilihanA;
    draft.optionBController.text = item.pilihanB;
    draft.optionCController.text = item.pilihanC;
    draft.optionDController.text = item.pilihanD;
    draft.selectedAnswer = item.jawaban.toUpperCase();

    setState(() {
      _showForm = true;
      _editingItem = item;
      _selectedMapel = _mapelOptions.contains(parsed.mapel)
          ? parsed.mapel
          : _mapelOptions.first;
      _jumlahSoalController.text = '1';
    });
  }

  void _closeForm() {
    setState(() {
      _showForm = false;
      _editingItem = null;
    });
  }

  Future<void> _submitForm() async {
    if (_drafts.isEmpty) {
      _showMessage('Tambahkan minimal 1 soal', isError: true);
      return;
    }

    for (int i = 0; i < _drafts.length; i++) {
      final draft = _drafts[i];
      if (!draft.isComplete) {
        _showMessage('Soal ${i + 1} belum lengkap', isError: true);
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      Map<String, dynamic> response = <String, dynamic>{
        'success': true,
        'message': 'Soal berhasil disimpan',
      };

      if (_editingItem == null) {
        for (int i = 0; i < _drafts.length; i++) {
          final draft = _drafts[i];
          final result = await LatihanSoalService.createSoalLatihan(
            pertanyaan: _buildStoredQuestion(
              draft.questionController.text.trim(),
              _selectedMapel,
            ),
            pilihanA: draft.optionAController.text.trim(),
            pilihanB: draft.optionBController.text.trim(),
            pilihanC: draft.optionCController.text.trim(),
            pilihanD: draft.optionDController.text.trim(),
            jawaban: draft.selectedAnswer,
            pembahasan: draft.pembahasanController.text.trim(),
            materiId: widget.materi?.id,
          );

          if (result['success'] != true) {
            response = {
              'success': false,
              'message': 'Gagal simpan Soal ${i + 1}: ${result['message']}',
            };
            break;
          }
        }
      } else {
        final draft = _drafts.first;
        response = await LatihanSoalService.updateSoalLatihan(
          soalId: _editingItem!.id,
          pertanyaan: _buildStoredQuestion(
            draft.questionController.text.trim(),
            _selectedMapel,
          ),
          pilihanA: draft.optionAController.text.trim(),
          pilihanB: draft.optionBController.text.trim(),
          pilihanC: draft.optionCController.text.trim(),
          pilihanD: draft.optionDController.text.trim(),
          jawaban: draft.selectedAnswer,
          pembahasan: draft.pembahasanController.text.trim(),
          materiId: widget.materi?.id ?? _editingItem!.materiId,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      if (response['success'] != true) {
        _showMessage(
          response['message'] ?? 'Gagal menyimpan soal',
          isError: true,
        );
        return;
      }

      _showMessage(response['message'] ?? 'Soal berhasil disimpan');
      _closeForm();
      await _loadItems();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage('Error: ${e.toString()}', isError: true);
    }
  }

  // _deleteItem removed — unused after refactor

  Future<void> _deleteLatihanByMapel(
    String mapel,
    List<SoalLatihan> items,
  ) async {
    if (items.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Hapus latihan ini?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          content: Text(
            'Semua soal latihan mapel $mapel akan dihapus permanen (${items.length} soal).',
            style: const TextStyle(color: Color(0xFF6B7280), height: 1.45),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Hapus Semua'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    int successCount = 0;
    String? failedMessage;

    for (final soal in items) {
      final result = await LatihanSoalService.deleteSoalLatihan(soal.id);
      if (result['success'] == true) {
        successCount++;
      } else {
        failedMessage = result['message']?.toString() ?? 'Gagal menghapus soal';
        break;
      }
    }

    if (!mounted) {
      return;
    }

    if (failedMessage != null) {
      _showMessage(
        'Proses berhenti. Berhasil hapus $successCount/${items.length} soal. $failedMessage',
        isError: true,
      );
    } else {
      _showMessage('Semua soal latihan $mapel berhasil dihapus');
    }

    await _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return MentorSidebarShell(
      activeMenuTitle: 'Soal Latihan',
      onMenuTap: _onSidebarMenuTap,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),

        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 20),
                    _buildTopSummary(),
                    const SizedBox(height: 16),
                    _buildToolbar(),
                    const SizedBox(height: 18),
                    _buildListView(),
                    if (_showForm) ...[
                      const SizedBox(height: 18),
                      _buildFormView(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _primaryBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withAlpha((0.15 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kelola Soal Latihan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Buat dan kelola soal latihan untuk siswa Anda',
                  style: TextStyle(
                    color: Colors.white.withAlpha((0.9 * 255).round()),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          const Icon(Icons.menu_book, color: Colors.white, size: 64),
        ],
      ),
    );
  }

  Widget _buildTopSummary() {
    final grouped = _groupByMapel(_items);
    final totalMapel = grouped.keys.length;
    final totalSoal = _items.length;
    final published = _items.isNotEmpty ? (_items.length / 2).ceil() : 0;
    final latihanTotal = grouped.isEmpty ? 0 : grouped.length;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildSummaryCard(
          icon: Icons.description_outlined,
          iconColor: const Color(0xFF2563EB),
          iconBg: const Color(0xFFEFF6FF),
          value: '$latihanTotal',
          label: 'Total Latihan',
        ),
        _buildSummaryCard(
          icon: Icons.check_circle_outline,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFDCFCE7),
          value: '$published',
          label: 'Dipublikasi',
        ),
        _buildSummaryCard(
          icon: Icons.tag,
          iconColor: const Color(0xFFF97316),
          iconBg: const Color(0xFFFFEDD5),
          value: '$totalSoal',
          label: 'Total Soal',
        ),
        _buildSummaryCard(
          icon: Icons.menu_book_outlined,
          iconColor: const Color(0xFF8B5CF6),
          iconBg: const Color(0xFFF3E8FF),
          value: '$totalMapel',
          label: 'Mata Pelajaran',
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final searchField = TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Cari soal latihan...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        );

        final classField = DropdownButtonFormField<String>(
          initialValue: _selectedClass,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          items: _classOptions
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedClass = v);
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.class_outlined,
              size: 18,
              color: Color(0xFF2563EB),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.4,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        );

        final addButton = SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _openCreateForm,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tambah Latihan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.softBorder),
          ),
          child: isWide
              ? Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 12),
                    SizedBox(width: 180, child: classField),
                    const SizedBox(width: 12),
                    addButton,
                  ],
                )
              : Column(
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    classField,
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: addButton),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildListView() {
    final filteredItems = _filteredItems();
    if (filteredItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                color: Color(0xFFFB5607),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Belum Ada Soal',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mulai tambahkan soal untuk latihan ini',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _openCreateForm,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah Soal Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB5607),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupByMapel(filteredItems);
    final mapelKeys = grouped.keys.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1400
            ? 4
            : width >= 1100
            ? 3
            : width >= 700
            ? 2
            : 1;
        final itemWidth = (width - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: mapelKeys.map((mapel) {
            final list = grouped[mapel] ?? const <SoalLatihan>[];
            return SizedBox(
              width: itemWidth,
              child: _buildMapelSectionCard(mapel, list),
            );
          }).toList(),
        );
      },
    );

    /* return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mapelKeys.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final mapel = mapelKeys[index];
        final list = grouped[mapel] ?? const <SoalLatihan>[];
        return _buildMapelSectionCard(mapel, list);
      },
    ); */
  }

  Widget _buildMapelSectionCard(String mapel, List<SoalLatihan> list) {
    final first = list.first;
    final parsed = _parseStoredQuestion(first.pertanyaan);
    final progressCount = list.length;
    final targetCount = progressCount < 5 ? 5 : progressCount;
    final progress = targetCount == 0 ? 0.0 : progressCount / targetCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Latihan $mapel - ${parsed.questionText.isNotEmpty ? parsed.questionText : 'Soal Latihan'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Dipublikasi',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                mapel,
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: const Text(
                  '-',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Text(
                  '30 menit',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$progressCount/$targetCount soal',
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Progress Soal',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ),
              Text(
                '$progressCount/$targetCount',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => MengelolaSoalScreen(
                          mapel: mapel,
                          latihanTitle: 'Latihan $mapel',
                        ),
                      ),
                    ).then((_) => _loadItems());
                  },
                  icon: const Icon(Icons.menu_book_outlined, size: 16),
                  label: const Text(
                    'Kelola Soal',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildActionIconButton(
                icon: Icons.edit_outlined,
                iconColor: const Color(0xFF6B7280),
                borderColor: const Color(0xFFD1D5DB),
                backgroundColor: const Color(0xFFF9FAFB),
                onPressed: () => _openEditForm(first),
                tooltip: 'Edit',
              ),
              const SizedBox(width: 8),
              _buildActionIconButton(
                icon: Icons.delete_outline,
                iconColor: const Color(0xFFEF4444),
                borderColor: const Color(0xFFD1D5DB),
                backgroundColor: const Color(0xFFFFF1F2),
                onPressed: () => _deleteLatihanByMapel(mapel, list),
                tooltip: 'Hapus',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required Color backgroundColor,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 40,
        height: 40,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            side: BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.zero,
            alignment: Alignment.center,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }

  // _optionTile removed — unused after removing question card

  Widget _buildFormView() {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (like Jadwal dialog)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _editingItem == null ? Icons.add : Icons.edit_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingItem == null
                              ? 'Tambah Latihan'
                              : 'Edit Latihan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _editingItem == null
                              ? 'Buat latihan dan soal untuk siswa.'
                              : 'Perbarui latihan yang sudah dibuat.',
                          style: const TextStyle(
                            color: Color(0xFFD9E4FF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _closeForm,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Judul Latihan *',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _judulController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Latihan Matematika Bab 1',
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.4,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Mata Pelajaran *',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMapel,
                    items: _mapelOptions
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedMapel = value);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.4,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _jumlahSoalController,
                          keyboardType: TextInputType.number,
                          enabled: _editingItem == null,
                          decoration: InputDecoration(
                            labelText: 'Jumlah Soal *',
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFD1D5DB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFD1D5DB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 1.4,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            if (_editingItem != null) return;
                            final parsed = int.tryParse(value) ?? 1;
                            _syncDraftCount(parsed.clamp(1, 20));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _durasiController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Durasi (Menit) *',
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFD1D5DB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFD1D5DB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _jadwalController,
                          readOnly: true,
                          onTap: _pickJadwalDate,
                          decoration: InputDecoration(
                            labelText: 'Jadwal Pelaksanaan',
                            hintText: '2026-04-30',
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFD1D5DB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFD1D5DB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Daftar Soal (Per Kolom)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      final cardWidth = isWide
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(_drafts.length, (index) {
                          return SizedBox(
                            width: cardWidth,
                            child: _buildQuestionEditorCard(index),
                          );
                        }),
                      );
                    },
                  ),
                  if (_editingItem == null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _drafts.length >= 20
                              ? null
                              : () {
                                  _syncDraftCount(_drafts.length + 1);
                                  _jumlahSoalController.text =
                                      '${_drafts.length}';
                                },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Tambah Kolom Soal'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Maksimal 20 soal',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _isSubmitting ? null : _closeForm,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
                              : Text(
                                  _editingItem == null
                                      ? 'Tambah Soal'
                                      : 'Simpan',
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionEditorCard(int index) {
    final draft = _drafts[index];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Soal ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              if (_editingItem == null && _drafts.length > 1)
                IconButton(
                  onPressed: () {
                    setState(() {
                      final removed = _drafts.removeAt(index);
                      removed.dispose();
                      _jumlahSoalController.text = '${_drafts.length}';
                    });
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                  tooltip: 'Hapus kolom soal',
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.questionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Pertanyaan *',
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.4,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 8),
          _buildOptionInput('A', draft.optionAController, draft),
          const SizedBox(height: 8),
          _buildOptionInput('B', draft.optionBController, draft),
          const SizedBox(height: 8),
          _buildOptionInput('C', draft.optionCController, draft),
          const SizedBox(height: 8),
          _buildOptionInput('D', draft.optionDController, draft),
          const SizedBox(height: 12),
          const Text(
            'Pembahasan (Opsional)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: draft.pembahasanController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tulis penjelasan untuk jawaban yang benar...',
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.4,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionInput(
    String key,
    TextEditingController controller,
    _QuestionDraft draft,
  ) {
    final isAnswer = draft.selectedAnswer == key;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Opsi $key',
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.4,
                ),
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text(isAnswer ? 'Kunci $key' : 'Set $key'),
          selected: isAnswer,
          onSelected: (_) {
            setState(() {
              draft.selectedAnswer = key;
            });
          },
        ),
      ],
    );
  }

  Map<String, List<SoalLatihan>> _groupByMapel(List<SoalLatihan> items) {
    final map = <String, List<SoalLatihan>>{};
    for (final item in items) {
      final parsed = _parseStoredQuestion(item.pertanyaan);
      map.putIfAbsent(parsed.mapel, () => <SoalLatihan>[]).add(item);
    }
    return map;
  }

  List<SoalLatihan> _filteredItems() {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final parsed = _parseStoredQuestion(item.pertanyaan);
      final matchesSearch =
          query.isEmpty ||
          item.pertanyaan.toLowerCase().contains(query) ||
          item.pilihanA.toLowerCase().contains(query) ||
          item.pilihanB.toLowerCase().contains(query) ||
          item.pilihanC.toLowerCase().contains(query) ||
          item.pilihanD.toLowerCase().contains(query) ||
          parsed.mapel.toLowerCase().contains(query);
      final matchesStatus =
          _selectedStatusFilter.isEmpty ||
          (_selectedStatusFilter == 'Dipublikasi' ? true : true);
      final matchesMapel =
          _selectedMapelFilter.isEmpty || parsed.mapel == _selectedMapelFilter;
      final matchesClass =
          _selectedClass == 'Semua Kelas' ||
          item.pertanyaan.contains('[$_selectedClass]');
      final matchesMateri =
          widget.materi == null || item.materiId == widget.materi!.id;

      return matchesSearch && matchesStatus && matchesMapel && matchesClass && matchesMateri;
    }).toList();
  }

  String _buildStoredQuestion(String text, String mapel) {
    return '[${mapel.trim()}] ${text.trim()}';
  }

  void _syncDraftCount(int requested) {
    final target = requested.clamp(1, 20);

    while (_drafts.length < target) {
      _drafts.add(_QuestionDraft());
    }

    while (_drafts.length > target) {
      final removed = _drafts.removeLast();
      removed.dispose();
    }
  }

  _ParsedQuestion _parseStoredQuestion(String raw) {
    final trimmed = raw.trim();
    final tagMatches = RegExp(
      r'\[(.+?)\]',
    ).allMatches(trimmed).map((m) => m.group(1)?.trim() ?? '').toList();
    if (tagMatches.isEmpty) {
      return _ParsedQuestion(mapel: _mapelOptions.first, questionText: trimmed);
    }

    // Last tag treated as mapel, others could be kelas or metadata
    final mapel = tagMatches.isNotEmpty ? tagMatches.last : _mapelOptions.first;
    // Remove all leading tags from question text
    final questionText = trimmed
        .replaceFirst(RegExp(r'^(?:\s*\[(?:.+?)\])*'), '')
        .trim();

    return _ParsedQuestion(
      mapel: mapel.isEmpty ? _mapelOptions.first : mapel,
      questionText: questionText,
    );
  }
}

class _ParsedQuestion {
  final String mapel;
  final String questionText;

  const _ParsedQuestion({required this.mapel, required this.questionText});
}

class _QuestionDraft {
  final TextEditingController questionController = TextEditingController();
  final TextEditingController optionAController = TextEditingController();
  final TextEditingController optionBController = TextEditingController();
  final TextEditingController optionCController = TextEditingController();
  final TextEditingController optionDController = TextEditingController();
  final TextEditingController pembahasanController = TextEditingController();
  String selectedAnswer = 'A';

  bool get isComplete {
    return questionController.text.trim().isNotEmpty &&
        optionAController.text.trim().isNotEmpty &&
        optionBController.text.trim().isNotEmpty &&
        optionCController.text.trim().isNotEmpty &&
        optionDController.text.trim().isNotEmpty;
  }

  void reset() {
    questionController.clear();
    optionAController.clear();
    optionBController.clear();
    optionCController.clear();
    optionDController.clear();
    pembahasanController.clear();
    selectedAnswer = 'A';
  }

  void dispose() {
    questionController.dispose();
    optionAController.dispose();
    optionBController.dispose();
    optionCController.dispose();
    optionDController.dispose();
    pembahasanController.dispose();
  }
}
