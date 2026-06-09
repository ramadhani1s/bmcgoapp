import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../routes/app_routes.dart';
import '../../models/mentor_competition_item.dart';
import '../../models/soal_kompetisi.dart';
import '../dashboard/jadwal_pembelajaran_screen.dart';
import '../dashboard/mentor_attendance_screen.dart';
import '../dashboard/mentor_olimpiade_screen.dart';
import '../mentor/materi_pembelajaran_screen.dart';
import '../../services/soal_kompetisi_service.dart';
import '../../widgets/mentor_sidebar_shell.dart';


class TryoutSoalManagementScreen extends StatefulWidget {
  final MentorCompetitionItem tryout;

  const TryoutSoalManagementScreen({super.key, required this.tryout});

  @override
  State<TryoutSoalManagementScreen> createState() =>
      _TryoutSoalManagementScreenState();
}

class _TryoutSoalManagementScreenState
    extends State<TryoutSoalManagementScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<SoalKompetisi> _soalList = [];
  SoalKompetisi? _editingItem;

  final TextEditingController _pertanyaanController = TextEditingController();
  final TextEditingController _pilihanAController = TextEditingController();
  final TextEditingController _pilihanBController = TextEditingController();
  final TextEditingController _pilihanCController = TextEditingController();
  final TextEditingController _pilihanDController = TextEditingController();
  final TextEditingController _pilihanEController = TextEditingController();
  final TextEditingController _pembahasanController = TextEditingController();

  String _selectedKategori = 'Penalaran Umum';
  String _selectedJawaban = 'A';

  final List<String> _kategoriOptions = const [
    'Penalaran Umum',
    'Pemahaman dan Penulisan Umum',
    'Pengetahuan dan Pemahaman Bacaan Matematika',
    'Pengetahuan Kuantitatif',
    'Penalaran Matematika',
    'Literasi Bahasa Indonesia',
  ];

  bool get _isFull =>
      _soalList.length >= (widget.tryout.totalQuestions > 0 ? widget.tryout.totalQuestions : 0);

  double get _progressValue {
    final total = widget.tryout.totalQuestions;
    if (total <= 0) return 0.0;
    return (_soalList.length / total).clamp(0.0, 1.0);
  }

  int get _progressPercent => (_progressValue * 100).round();

  @override
  void initState() {
    super.initState();
    _loadSoal();
  }

  @override
  void dispose() {
    _pertanyaanController.dispose();
    _pilihanAController.dispose();
    _pilihanBController.dispose();
    _pilihanCController.dispose();
    _pilihanDController.dispose();
    _pilihanEController.dispose();
    _pembahasanController.dispose();
    super.dispose();
  }

  Future<void> _loadSoal() async {
    setState(() => _isLoading = true);
    final soal = await SoalKompetisiService.getSoalByKompetisi(
      widget.tryout.id,
      'tryout',
    );
    if (!mounted) return;
    setState(() {
      _soalList = soal;
      _isLoading = false;
    });
  }

  void _clearForm() {
    _pertanyaanController.clear();
    _pilihanAController.clear();
    _pilihanBController.clear();
    _pilihanCController.clear();
    _pilihanDController.clear();
    _pilihanEController.clear();
    _pembahasanController.clear();
    _selectedJawaban = 'A';
    _selectedKategori = 'Penalaran Umum';
    _editingItem = null;
  }

  Future<void> _submitSoal() async {
    if (_pertanyaanController.text.trim().isEmpty) {
      _showSnackbar('Pertanyaan harus diisi', isError: true);
      return;
    }

    if (_pilihanAController.text.trim().isEmpty ||
        _pilihanBController.text.trim().isEmpty ||
        _pilihanCController.text.trim().isEmpty ||
        _pilihanDController.text.trim().isEmpty) {
      _showSnackbar('Pilihan A-D harus diisi', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      Map<String, dynamic> response;

      if (widget.tryout.id <= 0) {
        setState(() => _isSubmitting = false);
        _showSnackbar(
          'ID tryout tidak valid. Tidak dapat menyimpan soal.',
          isError: true,
        );
        return;
      }

      if (_editingItem == null) {
        if (kDebugMode) {
          debugPrint(
            'createSoal payload: kompetisi_id=${widget.tryout.id}, '
            'pertanyaan=${_pertanyaanController.text.trim()}, '
            'jawaban=$_selectedJawaban, kategori=$_selectedKategori',
          );
        }

        response = await SoalKompetisiService.createSoal(
          kompetisiId: widget.tryout.id,
          tipe: 'tryout',
          pertanyaan: _pertanyaanController.text.trim(),
          pilihanA: _pilihanAController.text.trim(),
          pilihanB: _pilihanBController.text.trim(),
          pilihanC: _pilihanCController.text.trim(),
          pilihanD: _pilihanDController.text.trim(),
          pilihanE: _pilihanEController.text.trim(),
          jawaban: _selectedJawaban,
          pembahasan: _pembahasanController.text.trim(),
          kategori: _selectedKategori,
        );
      } else {
        response = await SoalKompetisiService.updateSoal(
          soalId: _editingItem!.id,
          tipe: 'tryout',
          pertanyaan: _pertanyaanController.text.trim(),
          pilihanA: _pilihanAController.text.trim(),
          pilihanB: _pilihanBController.text.trim(),
          pilihanC: _pilihanCController.text.trim(),
          pilihanD: _pilihanDController.text.trim(),
          pilihanE: _pilihanEController.text.trim(),
          jawaban: _selectedJawaban,
          pembahasan: _pembahasanController.text.trim(),
          kategori: _selectedKategori,
        );
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response['success'] == true) {
        _showSnackbar(response['message'] ?? 'Soal berhasil disimpan');
        _clearForm();
        await _loadSoal();
      } else {
        if (kDebugMode) debugPrint('createSoal failed: ${response.toString()}');

        String userMsg = response['message'] ?? 'Gagal menyimpan soal';
        String? details;
        if (response.containsKey('details') && response['details'] != null) {
          details = response['details'].toString();
          final snippet =
              details.length > 200 ? '${details.substring(0, 200)}...' : details;
          userMsg = '$userMsg: $snippet';
        }

        _showSnackbar(userMsg, isError: true);

        if (details != null && mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Detail respons server',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              content: SingleChildScrollView(child: SelectableText(details!)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackbar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _deleteSoal(SoalKompetisi soal) async {
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
        title: const Text(
          'Hapus Soal?',
          style: TextStyle(
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
              const Text(
                'Apakah Anda yakin ingin menghapus soal ini?',
                style: TextStyle(
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
                        'Aksi ini tidak bisa dibatalkan. Butir soal beserta pilihan jawabannya akan dihapus secara permanen dari sistem.',
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
            onPressed: () => Navigator.pop(context, false),
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
            onPressed: () => Navigator.pop(context, true),
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

    final response = await SoalKompetisiService.deleteSoal(soal.id, 'tryout');
    if (!mounted) return;

    if (response['success'] == true) {
      _showSnackbar('Soal berhasil dihapus');
      await _loadSoal();
    } else {
      _showSnackbar(
        response['message'] ?? 'Gagal menghapus soal',
        isError: true,
      );
    }
  }

  void _editSoal(SoalKompetisi soal) {
    setState(() {
      _editingItem = soal;
      _pertanyaanController.text = soal.pertanyaan;
      _pilihanAController.text = soal.pilihanA;
      _pilihanBController.text = soal.pilihanB;
      _pilihanCController.text = soal.pilihanC;
      _pilihanDController.text = soal.pilihanD;
      _pilihanEController.text = soal.pilihanE;
      _pembahasanController.text = soal.pembahasan;
      _selectedJawaban =
          const ['A', 'B', 'C', 'D', 'E'].contains(soal.jawaban)
              ? soal.jawaban
              : 'A';
      _selectedKategori =
          soal.kategori.isEmpty ? 'Penalaran Umum' : soal.kategori;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
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
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showEditDialog() {
    final titleController = TextEditingController(text: widget.tryout.title);
    final durationController = TextEditingController(
      text: _extractDurasiMenit(widget.tryout.durationLabel).toString(),
    );
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
                    color: const Color(0xFF2563EB),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(41),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Try Out',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Ubah metadata Try Out.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Judul Try Out',
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: fieldBorder,
                            enabledBorder: fieldBorder,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 1.4,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Durasi (menit)',
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: fieldBorder,
                            enabledBorder: fieldBorder,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 1.4,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF6B7280),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Batal'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                _showSnackbar('Try Out berhasil diperbarui');
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Simpan'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: const Text(
          'Hapus Try Out?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus try out ini? Semua soal yang terkait akan dihapus secara permanen.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF4B5563),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
            onPressed: () {
              _showSnackbar('Try Out berhasil dihapus');
              Navigator.pop(context);
              Navigator.pop(context);
            },
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
  }

  int _extractDurasiMenit(String durationLabel) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(durationLabel);
    return match != null ? int.tryParse(match.group(1) ?? '150') ?? 150 : 150;
  }

  Map<String, int> _countByKategori() {
    final counts = <String, int>{};
    for (final soal in _soalList) {
      final k = soal.kategori.isEmpty ? 'Penalaran Umum' : soal.kategori;
      counts[k] = (counts[k] ?? 0) + 1;
    }
    return counts;
  }

  String _getShortKategori(String kategori) {
    const mapping = {
      'Penalaran Umum': 'PU',
      'Pemahaman dan Penulisan Umum': 'PPU',
      'Pengetahuan dan Pemahaman Bacaan Matematika': 'PBM',
      'Pengetahuan Kuantitatif': 'PK',
      'Penalaran Matematika': 'PM',
      'Literasi Bahasa Indonesia': 'LI',
    };
    return mapping[kategori] ?? 'XX';
  }

  void _onSidebarMenuTap(String title) {
    if (title == 'Dashboard') {
      Navigator.pushReplacementNamed(context, AppRoutes.mentorDashboard);
      return;
    }
    if (title == 'Jadwal Mengajar') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const JadwalPembelajaranScreen(mentorView: true),
        ),
      );
      return;
    }
    if (title == 'Absensi Kelas') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MentorAttendanceScreen()),
      );
      return;
    }
    if (title == 'Soal Latihan') {
      Navigator.pushReplacementNamed(context, AppRoutes.mentorExercise);
      return;
    }
    if (title == 'Try Out') {
      return;
    }
    if (title == 'Materi Pembelajaran') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MateriPembelajaranScreen(initialClass: null),
        ),
      );
      return;
    }
    if (title == 'Olimpiade Akademik') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MentorOlimpiadeScreen()),
      );
      return;
    }
  }

  // ─── WIDGETS (sama persis style olimpiade) ───────────────────────────────

  Widget _buildPilihanInput(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Pilihan $label',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoalCard(SoalKompetisi soal, int nomer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              '$nomer',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  soal.pertanyaan,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getShortKategori(
                          soal.kategori.isEmpty
                              ? 'Penalaran Umum'
                              : soal.kategori,
                        ),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4338CA),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Kunci: ${soal.jawaban}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _editSoal(soal),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteSoal(soal),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalQuestions = widget.tryout.totalQuestions;
    final counts = _countByKategori();

    return MentorSidebarShell(
      activeMenuTitle: 'Try Out',
      onMenuTap: _onSidebarMenuTap,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          title: const Text('Kelola Soal Try Out'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSoal,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── PROGRESS CARD (sama persis olimpiade) ─────────────
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: _isFull
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isFull
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFDBEAFE),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _isFull
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF2563EB),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _isFull
                                          ? Icons.warning_amber_rounded
                                          : Icons.quiz_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Progress Pembuatan Soal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _isFull
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  '$_progressPercent%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: _progressValue,
                              minHeight: 10,
                              backgroundColor: Colors.white,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isFull
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '${_soalList.length} soal terbuat',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF4B5563),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Flexible(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.flag_outlined,
                                      size: 14,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Target: $totalQuestions soal',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF4B5563),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_isFull) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFFEE2E2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Batas maksimal $totalQuestions soal sudah tercapai. Hapus beberapa soal untuk menambah.',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── KATEGORI TABS ─────────────────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _kategoriOptions.map((kategori) {
                          final shortName = _getShortKategori(kategori);
                          final count = counts[kategori] ?? 0;
                          final isSelected = _selectedKategori == kategori;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedKategori = kategori),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      shortName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF374151),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white.withAlpha(230)
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── FORM TAMBAH / EDIT SOAL (sama persis olimpiade) ───
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header biru
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(51),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _editingItem == null
                                        ? Icons.add_task
                                        : Icons.edit_note,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _editingItem == null
                                        ? 'Tambah Soal Baru'
                                        : 'Edit Soal',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (_editingItem != null)
                                  GestureDetector(
                                    onTap: () => setState(_clearForm),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(51),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Batal Edit',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Kategori
                                const Text(
                                  'Kategori Soal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      hoverColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                    ),
                                    child: PopupMenuButton<String>(
                                      tooltip: '',
                                      offset: const Offset(0, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      color: Colors.white,
                                      onSelected: (value) {
                                        setState(() => _selectedKategori = value);
                                      },
                                      itemBuilder: (context) {
                                        return _kategoriOptions.map((k) {
                                          return PopupMenuItem<String>(
                                            value: k,
                                            height: 38,
                                            child: Text(
                                              k,
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          );
                                        }).toList();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _selectedKategori,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF111827),
                                                  fontWeight: FontWeight.w600,
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
                                const SizedBox(height: 20),

                                // Pertanyaan
                                const Text(
                                  'Pertanyaan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _pertanyaanController,
                                    maxLines: 4,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Tulis pertanyaan soal di sini...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(14),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Pilihan Jawaban
                                const Text(
                                  'Pilihan Jawaban',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPilihanInput('A', _pilihanAController),
                                _buildPilihanInput('B', _pilihanBController),
                                _buildPilihanInput('C', _pilihanCController),
                                _buildPilihanInput('D', _pilihanDController),
                                _buildPilihanInput('E', _pilihanEController),
                                const SizedBox(height: 20),

                                // Jawaban Benar
                                const Text(
                                  'Jawaban Benar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      hoverColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                    ),
                                    child: PopupMenuButton<String>(
                                      tooltip: '',
                                      offset: const Offset(0, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      color: Colors.white,
                                      onSelected: (value) => setState(() => _selectedJawaban = value),
                                      itemBuilder: (context) {
                                        return ['A', 'B', 'C', 'D', 'E'].map((val) {
                                          return PopupMenuItem<String>(
                                            value: val,
                                            height: 38,
                                            child: Text(val),
                                          );
                                        }).toList();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _selectedJawaban,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF111827),
                                                fontWeight: FontWeight.w600,
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
                                const SizedBox(height: 20),

                                // Pembahasan
                                const Text(
                                  'Pembahasan (Opsional)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _pembahasanController,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Tambahkan pembahasan untuk siswa...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(14),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Tombol aksi
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isSubmitting ? null : _submitSoal,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF2563EB),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _editingItem == null
                                                    ? Icons.add
                                                    : Icons.save,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _editingItem == null
                                                    ? 'Tambah Soal'
                                                    : 'Simpan Perubahan',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── DAFTAR SOAL ───────────────────────────────────────
                    Text(
                      'Daftar Soal — $_selectedKategori (${counts[_selectedKategori] ?? 0})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),

                    Builder(
                      builder: (_) {
                        final filtered = _soalList
                            .where(
                              (s) =>
                                  (s.kategori.isEmpty
                                      ? 'Penalaran Umum'
                                      : s.kategori) ==
                                  _selectedKategori,
                            )
                            .toList();

                        if (filtered.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 40,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Belum ada soal untuk kategori ini',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _buildSoalCard(filtered[index], index + 1),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}