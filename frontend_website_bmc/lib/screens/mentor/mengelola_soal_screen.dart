import 'package:flutter/material.dart';

import '../../models/soal_latihan.dart';
import '../../services/latihan_soal_service.dart';
import '../../widgets/mentor_sidebar_shell.dart';
import '../../routes/app_routes.dart';
import '../dashboard/jadwal_pembelajaran_screen.dart';
import '../dashboard/mentor_attendance_screen.dart';
import '../dashboard/mentor_olimpiade_screen.dart';
import '../mentor/materi_pembelajaran_screen.dart';

class MengelolaSoalScreen extends StatefulWidget {
  final String mapel;
  final String latihanTitle;
  final int targetSoal;
  final String? kelas;
  final int? durasi;

  const MengelolaSoalScreen({
    super.key,
    required this.mapel,
    required this.latihanTitle,
    this.targetSoal = 5,
    this.kelas,
    this.durasi = 30,
  });

  @override
  State<MengelolaSoalScreen> createState() => _MengelolaSoalScreenState();
}

class _MengelolaSoalScreenState extends State<MengelolaSoalScreen> {
  List<SoalLatihan> _rawSoalList = [];
  List<SoalLatihan> _realSoalList = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _optionAController = TextEditingController();
  final TextEditingController _optionBController = TextEditingController();
  final TextEditingController _optionCController = TextEditingController();
  final TextEditingController _optionDController = TextEditingController();
  final TextEditingController _pembahasanController = TextEditingController();
  String _selectedAnswer = 'A';
  SoalLatihan? _editingItem;

  @override
  void initState() {
    super.initState();
    _loadSoal();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _pembahasanController.dispose();
    super.dispose();
  }

  Future<void> _loadSoal() async {
    setState(() => _isLoading = true);
    final items = await LatihanSoalService.getSoalLatihan();
    if (mounted) {
      setState(() {
        _rawSoalList = items.where((s) => s.latihanTitle == widget.latihanTitle).toList();
        _realSoalList = _rawSoalList.where((s) => !s.isSkeleton).toList();
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _questionController.clear();
    _optionAController.clear();
    _optionBController.clear();
    _optionCController.clear();
    _optionDController.clear();
    _pembahasanController.clear();
    _selectedAnswer = 'A';
    _editingItem = null;
  }

  Future<void> _submitSoal() async {
    if (_questionController.text.trim().isEmpty ||
        _optionAController.text.trim().isEmpty ||
        _optionBController.text.trim().isEmpty ||
        _optionCController.text.trim().isEmpty ||
        _optionDController.text.trim().isEmpty) {
      _showSnackbar('Semua pilihan jawaban A-D harus diisi', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    SoalLatihan? skeletonItem;
    for (final s in _rawSoalList) {
      if (s.isSkeleton) {
        skeletonItem = s;
        break;
      }
    }

    final newPertanyaan = SoalLatihan.buildPertanyaan(
      text: _questionController.text.trim(),
      kelas: widget.kelas ?? 'Kelas 10',
      mapel: widget.mapel,
      latihanTitle: widget.latihanTitle,
      durasi: widget.durasi ?? 30,
      target: widget.targetSoal,
      isSkeletonFlag: false,
    );

    Map<String, dynamic> res;
    if (_editingItem != null) {
      res = await LatihanSoalService.updateSoalLatihan(
        soalId: _editingItem!.id,
        pertanyaan: newPertanyaan,
        pilihanA: _optionAController.text.trim(),
        pilihanB: _optionBController.text.trim(),
        pilihanC: _optionCController.text.trim(),
        pilihanD: _optionDController.text.trim(),
        jawaban: _selectedAnswer,
        pembahasan: _pembahasanController.text.trim(),
      );
    } else if (skeletonItem != null) {
      res = await LatihanSoalService.updateSoalLatihan(
        soalId: skeletonItem.id,
        pertanyaan: newPertanyaan,
        pilihanA: _optionAController.text.trim(),
        pilihanB: _optionBController.text.trim(),
        pilihanC: _optionCController.text.trim(),
        pilihanD: _optionDController.text.trim(),
        jawaban: _selectedAnswer,
        pembahasan: _pembahasanController.text.trim(),
      );
    } else {
      res = await LatihanSoalService.createSoalLatihan(
        pertanyaan: newPertanyaan,
        pilihanA: _optionAController.text.trim(),
        pilihanB: _optionBController.text.trim(),
        pilihanC: _optionCController.text.trim(),
        pilihanD: _optionDController.text.trim(),
        jawaban: _selectedAnswer,
        pembahasan: _pembahasanController.text.trim(),
      );
    }

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (res['success'] == true) {
      _showSnackbar('Soal berhasil disimpan');
      _clearForm();
      await _loadSoal();
    } else {
      _showSnackbar(res['message'] ?? 'Gagal menyimpan soal', isError: true);
    }
  }

  Future<void> _deleteSoal(SoalLatihan soal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Soal?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Soal ini akan dihapus secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    if (_realSoalList.length == 1 && _realSoalList.first.id == soal.id) {
      final skeletonPertanyaan = SoalLatihan.buildPertanyaan(
        text: 'Placeholder',
        kelas: widget.kelas ?? 'Kelas 10',
        mapel: widget.mapel,
        latihanTitle: widget.latihanTitle,
        durasi: widget.durasi ?? 30,
        target: widget.targetSoal,
        isSkeletonFlag: true,
      );
      await LatihanSoalService.updateSoalLatihan(
        soalId: soal.id,
        pertanyaan: skeletonPertanyaan,
        pilihanA: '',
        pilihanB: '',
        pilihanC: '',
        pilihanD: '',
        jawaban: 'A',
        pembahasan: '',
      );
    } else {
      await LatihanSoalService.deleteSoalLatihan(soal.id);
    }

    await _loadSoal();
  }

  void _editSoal(SoalLatihan soal) {
    setState(() {
      _editingItem = soal;
      _questionController.text = soal.cleanPertanyaan;
      _optionAController.text = soal.pilihanA;
      _optionBController.text = soal.pilihanB;
      _optionCController.text = soal.pilihanC;
      _optionDController.text = soal.pilihanD;
      _pembahasanController.text = soal.pembahasan;
      _selectedAnswer = const ['A', 'B', 'C', 'D'].contains(soal.jawaban) ? soal.jawaban : 'A';
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSidebarMenuTap(String title) {
    if (title == 'Dashboard') {
      Navigator.pushReplacementNamed(context, AppRoutes.mentorDashboard);
    } else if (title == 'Jadwal Mengajar') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const JadwalPembelajaranScreen(mentorView: true)),
      );
    } else if (title == 'Absensi Kelas') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MentorAttendanceScreen()),
      );
    } else if (title == 'Soal Latihan') {
      // Tetap di halaman ini
    } else if (title == 'Try Out') {
      Navigator.pushReplacementNamed(context, AppRoutes.mentorTryout);
    } else if (title == 'Materi Pembelajaran') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MateriPembelajaranScreen(initialClass: null)),
      );
    } else if (title == 'Olimpiade Akademik') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MentorOlimpiadeScreen()),
      );
    }
  }

  // ==================== TEXT FIELD POLOS (TANPA WARNA) ====================

  Widget _buildOptionInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2563EB)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoalCard(SoalLatihan soal, int nomer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$nomer',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  soal.cleanPertanyaan,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEEBFF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Kunci: ${soal.jawaban}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                onPressed: () => _editSoal(soal),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteSoal(soal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressCount = _realSoalList.length;
    final progressValue = widget.targetSoal <= 0 ? 0.0 : (progressCount / widget.targetSoal).clamp(0.0, 1.0);
    final progressPercent = (progressValue * 100).round();
    final isFull = progressCount >= widget.targetSoal;

    return MentorSidebarShell(
      activeMenuTitle: 'Soal Latihan',
      onMenuTap: _onSidebarMenuTap,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          title: Text('Kelola Soal - ${widget.latihanTitle}'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
          elevation: 0,
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
              onPressed: _loadSoal,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading && _rawSoalList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PROGRESS CARD
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isFull
                              ? [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)]
                              : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
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
                                      color: isFull ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isFull ? Icons.warning_amber_rounded : Icons.quiz_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Progress Pembuatan Soal',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isFull ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  '$progressPercent%',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              minHeight: 10,
                              backgroundColor: Colors.white,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isFull ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$progressCount soal terbuat'),
                              Text('Target: ${widget.targetSoal} soal'),
                            ],
                          ),
                          if (isFull) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 16, color: Color(0xFFEF4444)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Batas maksimal ${widget.targetSoal} soal sudah tercapai.',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // FORM TAMBAH SOAL
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Biru
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
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
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _editingItem == null ? Icons.add_task : Icons.edit_note,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _editingItem == null ? 'Tambah Soal Baru' : 'Edit Soal',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                                  ),
                                ),
                                if (_editingItem != null)
                                  GestureDetector(
                                    onTap: _clearForm,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text('Batal Edit', style: TextStyle(fontSize: 12, color: Colors.white)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Body Form
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Pertanyaan
                                const Text('Pertanyaan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _questionController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Tulis pertanyaan soal di sini...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF2563EB)),
                                    ),
                                    contentPadding: const EdgeInsets.all(14),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Pilihan Jawaban (POLOS)
                                const Text('Pilihan Jawaban', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 12),
                                _buildOptionInput('A', _optionAController),
                                _buildOptionInput('B', _optionBController),
                                _buildOptionInput('C', _optionCController),
                                _buildOptionInput('D', _optionDController),
                                const SizedBox(height: 20),

                                // Jawaban Benar
                                const Text('Jawaban Benar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedAnswer,
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
                                    items: const [
                                      DropdownMenuItem(value: 'A', child: Text('A')),
                                      DropdownMenuItem(value: 'B', child: Text('B')),
                                      DropdownMenuItem(value: 'C', child: Text('C')),
                                      DropdownMenuItem(value: 'D', child: Text('D')),
                                    ],
                                    onChanged: (value) => setState(() => _selectedAnswer = value!),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Pembahasan
                                const Text('Pembahasan (Opsional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _pembahasanController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: 'Tambahkan pembahasan untuk siswa...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF2563EB)),
                                    ),
                                    contentPadding: const EdgeInsets.all(14),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Tombol Submit
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting || (isFull && _editingItem == null) ? null : _submitSoal,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFull && _editingItem == null ? Colors.grey : const Color(0xFF2563EB),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(_editingItem == null ? Icons.add : Icons.save, size: 18, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Text(
                                                _editingItem == null ? 'Tambah Soal' : 'Simpan Perubahan',
                                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
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

                    // DAFTAR SOAL
                    Text('Daftar Soal ($progressCount/${widget.targetSoal})', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    if (_realSoalList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: const Center(child: Text('Belum ada soal')),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _realSoalList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildSoalCard(_realSoalList[index], index + 1),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showTambahSoalDialog() {
    _clearForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tambah Soal Baru', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'Pertanyaan', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _optionAController,
                decoration: const InputDecoration(labelText: 'Pilihan A', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _optionBController,
                decoration: const InputDecoration(labelText: 'Pilihan B', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _optionCController,
                decoration: const InputDecoration(labelText: 'Pilihan C', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _optionDController,
                decoration: const InputDecoration(labelText: 'Pilihan D', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedAnswer,
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('A')),
                  DropdownMenuItem(value: 'B', child: Text('B')),
                  DropdownMenuItem(value: 'C', child: Text('C')),
                  DropdownMenuItem(value: 'D', child: Text('D')),
                ],
                onChanged: (value) => setState(() => _selectedAnswer = value!),
                decoration: const InputDecoration(labelText: 'Jawaban Benar', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pembahasanController,
                decoration: const InputDecoration(labelText: 'Pembahasan', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: _isSubmitting ? null : _submitSoal, child: const Text('Simpan')),
        ],
      ),
    );
  }
}