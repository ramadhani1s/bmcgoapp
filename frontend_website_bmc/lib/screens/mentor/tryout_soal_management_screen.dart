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
import '../../widgets/soal_overview_card.dart';

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

      // Guard: ensure kompetisi id is valid before sending
      if (widget.tryout.id <= 0) {
        setState(() => _isSubmitting = false);
        _showSnackbar(
          'ID tryout tidak valid. Tidak dapat menyimpan soal.',
          isError: true,
        );
        return;
      }

      if (_editingItem == null) {
        // Debug: print payload for server troubleshooting
        if (kDebugMode) {
          debugPrint(
            'createSoal payload: kompetisi_id=${widget.tryout.id}, pertanyaan=${_pertanyaanController.text.trim()}, jawaban=$_selectedJawaban, kategori=$_selectedKategori',
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
        // Log full response for debugging
        if (kDebugMode) debugPrint('createSoal failed: ${response.toString()}');

        // Build concise user-facing message. If server returned details, include short snippet.
        String userMsg = response['message'] ?? 'Gagal menyimpan soal';
        String? details;
        if (response.containsKey('details') && response['details'] != null) {
          details = response['details'].toString();
          final snippet = details.length > 200
              ? '${details.substring(0, 200)}...'
              : details;
          userMsg = '$userMsg: $snippet';
        }

        _showSnackbar(userMsg, isError: true);

        // If server provided details, show them in a dialog for copying/debugging
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
      _selectedJawaban = soal.jawaban;
      _selectedKategori = soal.kategori.isEmpty
          ? 'Penalaran Umum'
          : soal.kategori;
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showEditDialog() {
    final titleController = TextEditingController(text: widget.tryout.title);
    final durationController = TextEditingController(
      text: _extractDurasiMenit(widget.tryout.durationLabel).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Edit Try Out',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Try Out',
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
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
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
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
              // For now, just show success message
              // In production, you would call an API to update the tryout
              _showSnackbar('Try Out berhasil diperbarui');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Try Out',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus try out ini? Semua soal yang terkait akan dihapus juga.',
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
              // In production, you would call an API to delete the tryout
              _showSnackbar('Try Out berhasil dihapus');
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

  Map<String, int> _countByKategori() {
    final counts = <String, int>{};
    for (final soal in _soalList) {
      final kategori = soal.kategori.isEmpty ? 'Penalaran Umum' : soal.kategori;
      counts[kategori] = (counts[kategori] ?? 0) + 1;
    }
    return counts;
  }

  void _onSidebarMenuTap(String title) {
    if (title == 'Dashboard') {
      Navigator.pushReplacementNamed(context, AppRoutes.mentorDashboard);
      return;
    }
    if (title == 'Jadwal Mengajar') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const JadwalPembelajaranScreen()),
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
    }
  }

  @override
  Widget build(BuildContext context) {
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
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Card
                        SoalOverviewCard(
                          title: widget.tryout.title,
                          status: widget.tryout.isPublished
                              ? 'Dipublikasikan'
                              : 'Draft',
                          tanggal: widget.tryout.createdAt,
                          durasiMenit: _extractDurasiMenit(
                            widget.tryout.durationLabel,
                          ),
                          soalTerbuat: _soalList.length,
                          totalSoal: widget.tryout.totalQuestions,
                          kategoriProgress: {
                            'PU': _countByKategori()['Penalaran Umum'] ?? 0,
                            'PPU':
                                _countByKategori()['Pemahaman dan Penulisan Umum'] ??
                                0,
                            'PBM':
                                _countByKategori()['Pengetahuan dan Pemahaman Bacaan Matematika'] ??
                                0,
                            'PK':
                                _countByKategori()['Pengetahuan Kuantitatif'] ??
                                0,
                            'PM':
                                _countByKategori()['Penalaran Matematika'] ?? 0,
                            'Literasi':
                                _countByKategori()['Literasi Bahasa Indonesia'] ??
                                0,
                          },
                          onKelolaSoal: () {
                            // Already in soal management screen
                          },
                          onEdit: () => _showEditDialog(),
                          onDelete: () => _showDeleteConfirmation(),
                        ),
                        const SizedBox(height: 24),

                        // Kategori Navigation
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _kategoriOptions.map((kategori) {
                              final shortName = _getShortKategori(kategori);
                              final count = counts[kategori] ?? 0;
                              final isSelected = _selectedKategori == kategori;

                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(
                                      () => _selectedKategori = kategori,
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
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
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF2563EB,
                                                ).withOpacity(0.15),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                                ? Colors.white.withOpacity(0.9)
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

                        // Form Card (simplified to match Olimpiade style)
                        Container(
                          width: double.infinity,
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
                              const SizedBox(height: 10),

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
                              const SizedBox(height: 12),

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
                              const SizedBox(height: 12),

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
                              const SizedBox(height: 12),

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
                                  hintText:
                                      'Masukkan penjelasan untuk siswa...',
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
                              const SizedBox(height: 14),

                              // Action Buttons
                              Row(
                                children: [
                                  if (_editingItem != null)
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : () => _clearForm(),
                                        child: const Text('Batal Edit'),
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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2563EB,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Daftar Soal Section
                        Text(
                          'Daftar Soal (${_kategoriOptions[_kategoriOptions.indexOf(_selectedKategori)]})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Soal Cards
                        if (_soalList.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 48,
                                  color: const Color(0xFFD1D5DB),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Belum ada soal',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Mulai dengan menambahkan soal baru di form atas',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _soalList.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
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
                horizontal: 14,
                vertical: 12,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSoalCard(SoalKompetisi soal, int nomer) {
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Number, Kategori, Actions
                Row(
                  children: [
                    // Number badge
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$nomer',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Kategori badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDEEBFF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              soal.kategori.isEmpty
                                  ? 'Penalaran Umum'
                                  : soal.kategori,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDEEBFF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Kunci: ${soal.jawaban}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Actions
                    PopupMenuButton(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF6B7280),
                        size: 24,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(
                                Icons.edit,
                                size: 18,
                                color: Color(0xFF2563EB),
                              ),
                              SizedBox(width: 10),
                              Text('Edit', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                          onTap: () => _editSoal(soal),
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 10),
                              Text(
                                'Hapus',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _deleteSoal(soal),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Pertanyaan
                Text(
                  soal.pertanyaan,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Detail row: Total pilihan
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '5 Pilihan Jawaban',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (soal.pembahasan.isNotEmpty) ...[
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Color(0xFFCA8A04),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ada Pembahasan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFCA8A04),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Pembahasan section
          if (soal.pembahasan.isNotEmpty) ...[
            Container(height: 1, color: const Color(0xFFE5E7EB)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCA8A04),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.lightbulb,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Pembahasan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    soal.pembahasan,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF78350F),
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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
}
