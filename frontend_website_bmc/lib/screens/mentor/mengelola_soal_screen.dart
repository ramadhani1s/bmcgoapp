import 'package:flutter/material.dart';

import '../../models/soal_latihan.dart';
import '../../services/latihan_soal_service.dart';

class MengelolaSoalScreen extends StatefulWidget {
  final String mapel;
  final String latihanTitle;
  final int targetSoal;
  final String? kelas;
  final int? materiId;

  const MengelolaSoalScreen({
    super.key,
    required this.mapel,
    required this.latihanTitle,
    this.targetSoal = 5,
    this.kelas,
    this.materiId,
  });

  @override
  State<MengelolaSoalScreen> createState() => _MengelolaSoalScreenState();
}

class _MengelolaSoalScreenState extends State<MengelolaSoalScreen> {
  List<SoalLatihan> _soalList = [];
  bool _isLoading = false;
  bool _isAddingNew = false;

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _optionAController = TextEditingController();
  final TextEditingController _optionBController = TextEditingController();
  final TextEditingController _optionCController = TextEditingController();
  final TextEditingController _optionDController = TextEditingController();
  final TextEditingController _pembahasanController = TextEditingController();
  String _selectedAnswer = 'A';
  bool _isSubmitting = false;

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
        _soalList = items.where((s) {
          final hasMapel = s.pertanyaan.contains('[${widget.mapel}]');
          if (!hasMapel) return false;
          if (widget.kelas == null || widget.kelas!.isEmpty) return true;
          return s.pertanyaan.contains('[${widget.kelas}]');
        }).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitSoal() async {
    if (_questionController.text.trim().isEmpty ||
        _optionAController.text.trim().isEmpty ||
        _optionBController.text.trim().isEmpty ||
        _optionCController.text.trim().isEmpty ||
        _optionDController.text.trim().isEmpty) {
      _showSnackbar('Semua pilihan jawaban harus diisi', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final kelasTag = widget.kelas != null && widget.kelas!.isNotEmpty
        ? '[${widget.kelas}]'
        : '';
    final pertanyaan =
        '$kelasTag[${widget.mapel}] ${_questionController.text.trim()}';
    final res = await LatihanSoalService.createSoalLatihan(
      pertanyaan: pertanyaan,
      pilihanA: _optionAController.text.trim(),
      pilihanB: _optionBController.text.trim(),
      pilihanC: _optionCController.text.trim(),
      pilihanD: _optionDController.text.trim(),
      jawaban: _selectedAnswer,
      pembahasan: _pembahasanController.text.trim(),
      materiId: widget.materiId,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (res['success'] == true) {
      _showSnackbar('Soal berhasil ditambahkan');
      _clearForm();
      await _loadSoal();
      setState(() => _isAddingNew = false);
      // If target reached, close this flow and signal success to caller
      if (_soalList.length >= widget.targetSoal) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        Navigator.of(context).pop(); // close MengelolaSoalScreen
        Navigator.of(
          context,
        ).pop(true); // close CreateLatihanScreen with success
      }
    } else {
      final detailText = res['details'] != null
          ? '\nDetail: ${res['details']}'
          : '';
      _showSnackbar(
        '${res['message'] ?? 'Gagal menambah soal'}$detailText',
        isError: true,
      );
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
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Soal - ${widget.latihanTitle}'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
      ),
      body: _isLoading && _soalList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withAlpha((0.15 * 255).round()),
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
                                Text(
                                  'Kelola Soal - ${widget.latihanTitle}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Buat dan kelola soal untuk latihan ${widget.mapel}',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(
                                      (0.9 * 255).round(),
                                    ),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          const Icon(Icons.quiz, color: Colors.white, size: 64),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Progress section
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
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Progress Pembuatan Soal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_soalList.length} dari ${widget.targetSoal} soal dibuat',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: widget.targetSoal <= 0
                                ? 0
                                : (_soalList.length / widget.targetSoal).clamp(
                                    0,
                                    1,
                                  ),
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // List soal yang sudah dibuat
                    if (_soalList.isEmpty && !_isAddingNew) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFEDD5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.description_outlined,
                                color: Color(0xFFFB923C),
                              ),
                            ),
                            const SizedBox(height: 12),
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
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  setState(() => _isAddingNew = true),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Tambah Soal Pertama'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFB923C),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_soalList.isNotEmpty) ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _soalList.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) =>
                            _buildSoalCard(i, _soalList[i]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _isAddingNew = true),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah Soal Baru'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFB923C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],

                    // Form tambah soal
                    if (_isAddingNew) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tambah Soal Baru',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _questionController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: 'Pertanyaan *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildOptionInput('A', _optionAController),
                            const SizedBox(height: 8),
                            _buildOptionInput('B', _optionBController),
                            const SizedBox(height: 8),
                            _buildOptionInput('C', _optionCController),
                            const SizedBox(height: 8),
                            _buildOptionInput('D', _optionDController),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _pembahasanController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Pembahasan (Opsional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() => _isAddingNew = false);
                                    _clearForm();
                                  },
                                  child: const Text('Batal'),
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitSoal,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Simpan Soal'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOptionInput(String key, TextEditingController controller) {
    final isAnswer = _selectedAnswer == key;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Opsi $key',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text(isAnswer ? 'Kunci $key' : 'Set $key'),
          selected: isAnswer,
          onSelected: (_) => setState(() => _selectedAnswer = key),
        ),
      ],
    );
  }

  Widget _buildSoalCard(int index, SoalLatihan soal) {
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
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFFFB923C),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  soal.pertanyaan.replaceFirst('[${widget.mapel}]', '').trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Kunci: ${soal.jawaban}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
