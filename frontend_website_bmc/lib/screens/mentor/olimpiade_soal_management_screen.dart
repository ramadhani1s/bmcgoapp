import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

import '../../routes/app_routes.dart';

import '../../models/mentor_competition_item.dart';
import '../../models/soal_kompetisi.dart';
import '../dashboard/jadwal_pembelajaran_screen.dart';
import '../dashboard/mentor_attendance_screen.dart';
import '../mentor/materi_pembelajaran_screen.dart';
import '../../services/soal_kompetisi_service.dart';
import '../../widgets/mentor_sidebar_shell.dart';
import '../../widgets/soal_overview_card.dart';

class OlimpiadseSoalManagementScreen extends StatefulWidget {
  final MentorCompetitionItem olimpiade;

  const OlimpiadseSoalManagementScreen({super.key, required this.olimpiade});

  @override
  State<OlimpiadseSoalManagementScreen> createState() =>
      _OlimpiadseSoalManagementScreenState();
}

class _OlimpiadseSoalManagementScreenState
    extends State<OlimpiadseSoalManagementScreen> {
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

  String _selectedJawaban = 'A';

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
      widget.olimpiade.id,
      'olimpiade',
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

      if (_editingItem == null) {
        response = await SoalKompetisiService.createSoal(
          kompetisiId: widget.olimpiade.id,
          tipe: 'olimpiade',
          pertanyaan: _pertanyaanController.text.trim(),
          pilihanA: _pilihanAController.text.trim(),
          pilihanB: _pilihanBController.text.trim(),
          pilihanC: _pilihanCController.text.trim(),
          pilihanD: _pilihanDController.text.trim(),
          pilihanE: _pilihanEController.text.trim(),
          jawaban: _selectedJawaban,
          pembahasan: _pembahasanController.text.trim(),
        );
      } else {
        response = await SoalKompetisiService.updateSoal(
          soalId: _editingItem!.id,
          tipe: 'olimpiade',
          pertanyaan: _pertanyaanController.text.trim(),
          pilihanA: _pilihanAController.text.trim(),
          pilihanB: _pilihanBController.text.trim(),
          pilihanC: _pilihanCController.text.trim(),
          pilihanD: _pilihanDController.text.trim(),
          pilihanE: _pilihanEController.text.trim(),
          jawaban: _selectedJawaban,
          pembahasan: _pembahasanController.text.trim(),
        );
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response['success'] == true) {
        _showSnackbar(response['message'] ?? 'Soal berhasil disimpan');
        _clearForm();
        await _loadSoal();
      } else {
        _showSnackbar(
          response['message'] ?? 'Gagal menyimpan soal',
          isError: true,
        );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Soal?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        content: const Text(
          'Soal ini akan dihapus permanen.',
          style: TextStyle(color: Color(0xFF6B7280), height: 1.45),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final response = await SoalKompetisiService.deleteSoal(
      soal.id,
      'olimpiade',
    );
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
      _selectedJawaban = soal.jawaban;
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
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showEditDialog() {
    final titleController = TextEditingController(text: widget.olimpiade.title);
    final durationController = TextEditingController(
      text: _extractDurasiMenit(widget.olimpiade.durationLabel).toString(),
    );

    final dateController = TextEditingController(
      text: widget.olimpiade.scheduleLabel,
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
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, 0.18),
                  blurRadius: 30,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
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
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.emoji_events_outlined,
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
                                'Edit Olimpiade',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ubah metadata Olimpiade. Tambahkan tanggal pelaksanaan.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  height: 1.3,
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
                            labelText: 'Judul Olimpiade',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
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
                        const SizedBox(height: 12),
                        TextField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Durasi (menit)',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
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
                        const SizedBox(height: 12),
                        TextField(
                          controller: dateController,
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.tryParse(dateController.text) ??
                                  DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              dateController.text =
                                  '${picked.day} ${_getMonthName(picked.month)} ${picked.year}';
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Tanggal Olimpiade',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
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
                                _showSnackbar('Olimpiade berhasil diperbarui');
                                Navigator.pop(context);
                              },
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Olimpiade',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus olimpiade ini? Semua soal yang terkait akan dihapus juga.',
          style: TextStyle(color: Color(0xFF6B7280), height: 1.45),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // For now, just show success message and pop to previous screen
              // In production, you would call an API to delete the olimpiade
              _showSnackbar('Olimpiade berhasil dihapus');
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  int _extractDurasiMenit(String durationLabel) {
    // Extract numeric value from duration label (e.g., "150 menit" -> 150)
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(durationLabel);
    return match != null ? int.tryParse(match.group(1) ?? '150') ?? 150 : 150;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
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
      Navigator.pushNamed(context, AppRoutes.mentorExercise);
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
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MentorSidebarShell(
      activeMenuTitle: 'Olimpiade Akademik',
      onMenuTap: _onSidebarMenuTap,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          title: const Text('Kelola Soal Olimpiade'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Card
                        SoalOverviewCard(
                          title: widget.olimpiade.title,
                          status: widget.olimpiade.isPublished
                              ? 'Dipublikasikan'
                              : 'Draft',
                          tanggal: widget.olimpiade.createdAt,
                          durasiMenit: _extractDurasiMenit(
                            widget.olimpiade.durationLabel,
                          ),
                          soalTerbuat: _soalList.length,
                          totalSoal: widget.olimpiade.totalQuestions,
                          kategoriProgress: {
                            'Soal': widget.olimpiade.totalQuestions,
                          },
                          onKelolaSoal: () {
                            // Already in soal management screen
                          },
                          onEdit: () => _showEditDialog(),
                          onDelete: () => _showDeleteConfirmation(),
                        ),
                        const SizedBox(height: 32),

                        // Form
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _editingItem == null
                                    ? 'Tambah Soal Baru'
                                    : 'Edit Soal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Pertanyaan
                              const Text(
                                'Pertanyaan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _pertanyaanController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Masukkan pertanyaan soal...',
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
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Pilihan Jawaban
                              const Text(
                                'Pilihan Jawaban',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildPilihanInput('A', _pilihanAController),
                              const SizedBox(height: 8),
                              _buildPilihanInput('B', _pilihanBController),
                              const SizedBox(height: 8),
                              _buildPilihanInput('C', _pilihanCController),
                              const SizedBox(height: 8),
                              _buildPilihanInput('D', _pilihanDController),
                              const SizedBox(height: 8),
                              _buildPilihanInput('E', _pilihanEController),
                              const SizedBox(height: 16),

                              // Jawaban Benar
                              const Text(
                                'Jawaban Benar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedJawaban,
                                items: ['A', 'B', 'C', 'D', 'E']
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedJawaban = value);
                                  }
                                },
                                decoration: InputDecoration(
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Pembahasan
                              const Text(
                                'Pembahasan (Opsional)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _pembahasanController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Masukkan pembahasan soal...',
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
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Action Buttons
                              Row(
                                children: [
                                  if (_editingItem != null)
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : () => _clearForm(),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF64748B,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Batal Edit'),
                                      ),
                                    ),
                                  if (_editingItem != null)
                                    const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isSubmitting
                                          ? null
                                          : _submitSoal,
                                      icon: const Icon(Icons.add, size: 16),
                                      label: Text(
                                        _editingItem == null
                                            ? 'Tambah Soal'
                                            : 'Simpan Perubahan',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2563EB,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Daftar Soal
                        if (_soalList.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Belum ada soal',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _soalList.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final soal = _soalList[index];
                              return _buildSoalCard(soal, index + 1);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPilihanInput(String label, TextEditingController controller) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Pilihan $label',
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
                vertical: 10,
              ),
              isDense: true,
            ),
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
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor),
        ),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.03),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox.square(
            dimension: 36,
            child: Center(child: Icon(icon, size: 17, color: iconColor)),
          ),
        ),
      ),
    );
  }

  Widget _buildSoalCard(SoalKompetisi soal, int nomer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4D3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$nomer',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      soal.pertanyaan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kunci: ${soal.jawaban}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildActionIconButton(
                icon: Icons.edit_outlined,
                iconColor: const Color(0xFF6B7280),
                borderColor: const Color(0xFFE5E7EB),
                onPressed: () => _editSoal(soal),
                tooltip: 'Edit',
              ),
              const SizedBox(width: 8),
              _buildActionIconButton(
                icon: Icons.delete_outline,
                iconColor: const Color(0xFFEF4444),
                borderColor: const Color(0xFFFECACA),
                onPressed: () => _deleteSoal(soal),
                tooltip: 'Hapus',
              ),
            ],
          ),
          if (soal.pembahasan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.blueLightBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pembahasan:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    soal.pembahasan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
