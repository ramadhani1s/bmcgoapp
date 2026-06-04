import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/mentor_competition_item.dart';
import '../../models/soal_kompetisi.dart';
import '../../routes/app_routes.dart';
import '../../services/soal_kompetisi_service.dart';
import '../dashboard/jadwal_pembelajaran_screen.dart';
import '../dashboard/mentor_attendance_screen.dart';
import '../dashboard/mentor_olimpiade_screen.dart';
import '../mentor/materi_pembelajaran_screen.dart';
import '../../widgets/mentor_sidebar_shell.dart';
import '../../widgets/soal_overview_card.dart';

class OlimpiadeSoalManagementScreen extends StatefulWidget {
  final MentorCompetitionItem olimpiade;

  const OlimpiadeSoalManagementScreen({super.key, required this.olimpiade});

  @override
  State<OlimpiadeSoalManagementScreen> createState() =>
      _OlimpiadeSoalManagementScreenState();
}

class _OlimpiadeSoalManagementScreenState
    extends State<OlimpiadeSoalManagementScreen> {
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

  // 🔥 GETTER UNTUK VALIDASI BATAS SOAL
  bool get _isFull => _soalList.length >= widget.olimpiade.totalQuestions;
  
  double get _progressValue {
    if (widget.olimpiade.totalQuestions == 0) return 0.0;
    final progress = _soalList.length / widget.olimpiade.totalQuestions;
    return progress.clamp(0.0, 1.0);
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

  // 🔥 PERBAIKAN: LOAD SOAL DENGAN SORTING
  Future<void> _loadSoal() async {
    setState(() => _isLoading = true);
    final soal = await SoalKompetisiService.getSoalByKompetisi(
      widget.olimpiade.id,
      'olimpiade',
    );
    if (!mounted) return;
    
    // 🔥 URUTKAN SOAL BERDASARKAN ID
    soal.sort((a, b) => a.id.compareTo(b.id));
    
    setState(() {
      _soalList = soal;
      _isLoading = false;
    });
    print('📊 Loaded ${_soalList.length} soal for olimpiade ${widget.olimpiade.id}');
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
    // 🔥 VALIDASI: CEK APAKAH SUDAH PENUH
    if (_isFull) {
      _showSnackbar(
        '⚠️ Batas maksimal ${widget.olimpiade.totalQuestions} soal sudah tercapai!',
        isError: true,
      );
      return;
    }

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
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Soal ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final response = await SoalKompetisiService.deleteSoal(soal.id, 'olimpiade');
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
      _selectedJawaban = const ['A', 'B', 'C', 'D', 'E'].contains(soal.jawaban) ? soal.jawaban : 'A';
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
    void _showTambahSoalDialog() {
    // 🔥 CEK APAKAH SUDAH PENUH
    if (_isFull) {
      _showSnackbar(
        '⚠️ Batas maksimal ${widget.olimpiade.totalQuestions} soal sudah tercapai!',
        isError: true,
      );
      return;
    }
    
    _clearForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Soal Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _pertanyaanController,
                decoration: const InputDecoration(labelText: 'Pertanyaan'),
                maxLines: 3,
              ),
              TextField(
                controller: _pilihanAController,
                decoration: const InputDecoration(labelText: 'Pilihan A'),
              ),
              TextField(
                controller: _pilihanBController,
                decoration: const InputDecoration(labelText: 'Pilihan B'),
              ),
              TextField(
                controller: _pilihanCController,
                decoration: const InputDecoration(labelText: 'Pilihan C'),
              ),
              TextField(
                controller: _pilihanDController,
                decoration: const InputDecoration(labelText: 'Pilihan D'),
              ),
              TextField(
                controller: _pilihanEController,
                decoration: const InputDecoration(labelText: 'Pilihan E'),
              ),
              const SizedBox(height: 12),
              // 🔥 DROPDOWN JAWABAN YANG SUDAH DIPERBAIKI
              DropdownButtonFormField<String>(
                value: _selectedJawaban,
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('A')),
                  DropdownMenuItem(value: 'B', child: Text('B')),
                  DropdownMenuItem(value: 'C', child: Text('C')),
                  DropdownMenuItem(value: 'D', child: Text('D')),
                  DropdownMenuItem(value: 'E', child: Text('E')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedJawaban = value);
                },
                decoration: const InputDecoration(
                  labelText: 'Jawaban Benar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pembahasanController,
                decoration: const InputDecoration(labelText: 'Pembahasan'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitSoal,
            child: const Text('Simpan'),
          ),
        ],
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
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Judul Olimpiade'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Durasi (menit)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateController,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    dateController.text = picked.toLocal().toString().split(' ')[0];
                  }
                },
                decoration: const InputDecoration(labelText: 'Tanggal'),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _showSnackbar('Olimpiade berhasil diperbarui');
                      Navigator.pop(context);
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Olimpiade'),
        content: const Text('Apakah Anda yakin ingin menghapus olimpiade ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              _showSnackbar('Olimpiade berhasil dihapus');
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
    Navigator.pushReplacementNamed(context, AppRoutes.mentorTryout);
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
      MaterialPageRoute(
        builder: (_) => const MentorOlimpiadeScreen(),
      ),
    );
    return;
  }
}
  Widget _buildPilihanInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Pilihan $label',
                border: const OutlineInputBorder(),
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
                Text(
                  'Kunci: ${soal.jawaban}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    return MentorSidebarShell(
      activeMenuTitle: 'Olimpiade Akademik',
      onMenuTap: _onSidebarMenuTap,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          title: const Text('Kelola Soal Olimpiade'),
          backgroundColor: Colors.white,
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
                    // 🔥 PROGRESS CARD
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Progress Pembuatan Soal',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _isFull ? Colors.red.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$_progressPercent%',
                                  style: TextStyle(
                                    color: _isFull ? Colors.red : Colors.green.shade700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _progressValue,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              _isFull ? Colors.red : const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_soalList.length} soal terbuat'),
                              Text('Target: ${widget.olimpiade.totalQuestions} soal'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // FORM TAMBAH SOAL
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingItem == null ? 'Tambah Soal Baru' : 'Edit Soal',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _pertanyaanController,
                            decoration: const InputDecoration(labelText: 'Pertanyaan'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          const Text('Pilihan Jawaban'),
                          _buildPilihanInput('A', _pilihanAController),
                          _buildPilihanInput('B', _pilihanBController),
                          _buildPilihanInput('C', _pilihanCController),
                          _buildPilihanInput('D', _pilihanDController),
                          _buildPilihanInput('E', _pilihanEController),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedJawaban,
                            dropdownColor: Colors.white,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'A', child: Text('A')),
                              DropdownMenuItem(value: 'B', child: Text('B')),
                              DropdownMenuItem(value: 'C', child: Text('C')),
                              DropdownMenuItem(value: 'D', child: Text('D')),
                              DropdownMenuItem(value: 'E', child: Text('E')),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => _selectedJawaban = value);
                            },
                            decoration: InputDecoration(
                              labelText: 'Jawaban Benar',
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
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pembahasanController,
                            decoration: const InputDecoration(labelText: 'Pembahasan'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _isSubmitting || _isFull ? null : _submitSoal,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: Text(
                              _editingItem == null ? 'Tambah Soal' : 'Simpan Perubahan',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFull ? Colors.grey : const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // DAFTAR SOAL
                    Text(
                      'Daftar Soal (${_soalList.length}/${widget.olimpiade.totalQuestions})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    if (_soalList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('Belum ada soal')),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _soalList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final soal = _soalList[index];
                          return _buildSoalCard(soal, index + 1);
                        },
                      ),
                  ],
                ),
              ),
        floatingActionButton: _isFull
            ? null
            : FloatingActionButton(
                onPressed: _showTambahSoalDialog,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}