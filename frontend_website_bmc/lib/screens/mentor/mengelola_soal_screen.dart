import 'package:flutter/material.dart';

import '../../models/soal_latihan.dart';
import '../../services/latihan_soal_service.dart';

class MengelolaSoalScreen extends StatefulWidget {
  final String mapel;
  final String latihanTitle;
  final int targetSoal;
  final String? kelas;
  final int? materiId;
  final int? durasi;

  const MengelolaSoalScreen({
    super.key,
    required this.mapel,
    required this.latihanTitle,
    this.targetSoal = 5,
    this.kelas,
 
    this.materiId,
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
        // Filter out skeleton placeholder questions from the visible list
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

    // Find if we have a skeleton placeholder question in the database
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
      // Promote the skeleton placeholder to be the first real question
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
        title: const Text(
          'Hapus Soal?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Soal ini akan dihapus secara permanen.'),
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

    setState(() => _isLoading = true);

    // If this is the last question, convert it back to a skeleton instead of deleting
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

  Widget _buildOptionInput(String label, TextEditingController controller) {
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

  Widget _buildSoalCard(SoalLatihan soal, int nomer) {
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
                  soal.cleanPertanyaan,
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
    final progressCount = _realSoalList.length;
    final progressValue = widget.targetSoal <= 0 ? 0.0 : (progressCount / widget.targetSoal).clamp(0.0, 1.0);
    final progressPercent = (progressValue * 100).round();
    final isFull = progressCount >= widget.targetSoal;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('Kelola Soal - ${widget.latihanTitle}'),
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
      body: _isLoading && _rawSoalList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Progress Pembuatan Soal',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isFull ? Colors.red.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$progressPercent%',
                                style: TextStyle(
                                  color: isFull ? Colors.red : Colors.green.shade700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            isFull ? Colors.red : const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$progressCount soal terbuat'),
                            Text('Target: ${widget.targetSoal} soal'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Tambah / Edit Soal
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
                          _editingItem == null ? 'Tambah Soal Baru' : 'Edit Soal',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _questionController,
                          decoration: const InputDecoration(labelText: 'Pertanyaan', border: OutlineInputBorder()),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        const Text('Pilihan Jawaban', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        _buildOptionInput('A', _optionAController),
                        _buildOptionInput('B', _optionBController),
                        _buildOptionInput('C', _optionCController),
                        _buildOptionInput('D', _optionDController),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedAnswer,
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
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _selectedAnswer = value);
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
                          decoration: const InputDecoration(labelText: 'Pembahasan', border: OutlineInputBorder()),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting || (isFull && _editingItem == null) ? null : _submitSoal,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: Text(
                            _editingItem == null ? 'Tambah Soal' : 'Simpan Perubahan',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFull && _editingItem == null ? Colors.grey : const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Daftar Soal
                  Text(
                    'Daftar Soal ($progressCount/${widget.targetSoal})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (_realSoalList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(child: Text('Belum ada soal')),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _realSoalList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final soal = _realSoalList[index];
                        return _buildSoalCard(soal, index + 1);
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
