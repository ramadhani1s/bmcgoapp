import 'package:flutter/material.dart';

import '../../models/soal_latihan.dart';
import '../../services/latihan_soal_service.dart';

class LatihanSoalScreen extends StatefulWidget {
  const LatihanSoalScreen({super.key});

  @override
  State<LatihanSoalScreen> createState() => _LatihanSoalScreenState();
}

class _LatihanSoalScreenState extends State<LatihanSoalScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showForm = false;
  List<SoalLatihan> _items = const [];
  SoalLatihan? _editingItem;

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _optionAController = TextEditingController();
  final TextEditingController _optionBController = TextEditingController();
  final TextEditingController _optionCController = TextEditingController();
  final TextEditingController _optionDController = TextEditingController();

  final List<String> _mapelOptions = const [
    'Matematika',
    'Fisika',
    'Kimia',
    'Biologi',
    'Bahasa Indonesia',
    'Bahasa Inggris',
  ];

  String _selectedAnswer = 'A';
  String _selectedMapel = 'Matematika';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
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

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF2563EB),
      ),
    );
  }

  void _openCreateForm() {
    setState(() {
      _showForm = true;
      _editingItem = null;
      _questionController.clear();
      _optionAController.clear();
      _optionBController.clear();
      _optionCController.clear();
      _optionDController.clear();
      _selectedAnswer = 'A';
      _selectedMapel = _mapelOptions.first;
    });
  }

  void _openEditForm(SoalLatihan item) {
    final parsed = _parseStoredQuestion(item.pertanyaan);

    setState(() {
      _showForm = true;
      _editingItem = item;
      _questionController.text = parsed.questionText;
      _optionAController.text = item.pilihanA;
      _optionBController.text = item.pilihanB;
      _optionCController.text = item.pilihanC;
      _optionDController.text = item.pilihanD;
      _selectedAnswer = item.jawaban.toUpperCase();
      _selectedMapel = _mapelOptions.contains(parsed.mapel)
          ? parsed.mapel
          : _mapelOptions.first;
    });
  }

  void _closeForm() {
    setState(() {
      _showForm = false;
      _editingItem = null;
      _selectedAnswer = 'A';
    });
  }

  Future<void> _submitForm() async {
    final pertanyaan = _questionController.text.trim();
    final pilihanA = _optionAController.text.trim();
    final pilihanB = _optionBController.text.trim();
    final pilihanC = _optionCController.text.trim();
    final pilihanD = _optionDController.text.trim();
    final storedQuestion = _buildStoredQuestion(pertanyaan, _selectedMapel);

    if (pertanyaan.isEmpty ||
        pilihanA.isEmpty ||
        pilihanB.isEmpty ||
        pilihanC.isEmpty ||
        pilihanD.isEmpty) {
      _showMessage('Semua field wajib diisi', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    Map<String, dynamic> response;
    if (_editingItem == null) {
      response = await LatihanSoalService.createSoalLatihan(
        pertanyaan: storedQuestion,
        pilihanA: pilihanA,
        pilihanB: pilihanB,
        pilihanC: pilihanC,
        pilihanD: pilihanD,
        jawaban: _selectedAnswer,
      );
    } else {
      response = await LatihanSoalService.updateSoalLatihan(
        soalId: _editingItem!.id,
        pertanyaan: storedQuestion,
        pilihanA: pilihanA,
        pilihanB: pilihanB,
        pilihanC: pilihanC,
        pilihanD: pilihanD,
        jawaban: _selectedAnswer,
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
  }

  Future<void> _deleteItem(SoalLatihan item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus soal latihan?'),
          content: const Text('Data soal ini akan dihapus permanen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final response = await LatihanSoalService.deleteSoalLatihan(item.id);
    if (!mounted) {
      return;
    }

    if (response['success'] != true) {
      _showMessage(
        response['message'] ?? 'Gagal menghapus soal',
        isError: true,
      );
      return;
    }

    _showMessage(response['message'] ?? 'Soal berhasil dihapus');
    await _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        title: Text(_showForm ? 'Tambah Soal Baru' : 'Kelola Soal'),
        actions: [
          IconButton(
            onPressed: _loadItems,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Container(
              margin: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        _buildTopSummary(),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _showForm
                              ? _buildFormView()
                              : _buildListView(),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSummary() {
    final targetCount = _items.length > 5 ? _items.length : 5;
    final progressCount = _items.length;
    final progress = targetCount == 0 ? 0.0 : progressCount / targetCount;
    final grouped = _groupByMapel(_items);
    final totalMapel = grouped.keys.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildStatChip(
                'Total Soal',
                '$progressCount',
                Icons.fact_check_outlined,
              ),
              _buildStatChip(
                'Mata Pelajaran',
                '$totalMapel',
                Icons.menu_book_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Progress Pembuatan Soal',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              InkWell(
                onTap: _openCreateForm,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFB5607),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$progressCount dari $targetCount soal telah dibuat',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFB5607),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(targetCount, (index) {
                final number = index + 1;
                final isDone = index < progressCount;
                return Container(
                  width: 34,
                  height: 24,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        color: isDone
                            ? const Color(0xFF166534)
                            : const Color(0xFF6B7280),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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

    final grouped = _groupByMapel(_items);
    final mapelKeys = grouped.keys.toList();

    return ListView.separated(
      itemCount: mapelKeys.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final mapel = mapelKeys[index];
        final list = grouped[mapel] ?? const <SoalLatihan>[];
        return _buildMapelSectionCard(mapel, list);
      },
    );
  }

  Widget _buildMapelSectionCard(String mapel, List<SoalLatihan> list) {
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
              Expanded(
                child: Text(
                  'Latihan $mapel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${list.length} soal',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < list.length; i++) ...[
            _buildQuestionCard(list[i], i + 1),
            if (i < list.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionCard(SoalLatihan item, int indexNumber) {
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
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$indexNumber',
                    style: const TextStyle(
                      color: Color(0xFFFB5607),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Soal Latihan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Text(
                'Kunci ${item.jawaban.toUpperCase()}',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _parseStoredQuestion(item.pertanyaan).questionText,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _optionTile('A', item.pilihanA, item.jawaban),
          const SizedBox(height: 6),
          _optionTile('B', item.pilihanB, item.jawaban),
          const SizedBox(height: 6),
          _optionTile('C', item.pilihanC, item.jawaban),
          const SizedBox(height: 6),
          _optionTile('D', item.pilihanD, item.jawaban),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _openEditForm(item),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _deleteItem(item),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
                label: const Text(
                  'Hapus',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _optionTile(String key, String text, String answer) {
    final isAnswer = answer.toUpperCase() == key;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isAnswer ? const Color(0xFFECFDF3) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAnswer ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        '$key  $text',
        style: TextStyle(
          color: isAnswer ? const Color(0xFF166534) : const Color(0xFF374151),
          fontWeight: isAnswer ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mata Pelajaran *',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
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
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedMapel = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pertanyaan *',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _questionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tulis pertanyaan soal di sini...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Pilihan Jawaban',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            _buildOptionEditor('A', _optionAController),
            const SizedBox(height: 8),
            _buildOptionEditor('B', _optionBController),
            const SizedBox(height: 8),
            _buildOptionEditor('C', _optionCController),
            const SizedBox(height: 8),
            _buildOptionEditor('D', _optionDController),
            const SizedBox(height: 14),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _isSubmitting ? null : _closeForm,
                  child: const Text('Batal'),
                ),
                const Spacer(),
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFB5607),
                      foregroundColor: Colors.white,
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
                        : Text(_editingItem == null ? 'Tambah Soal' : 'Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionEditor(String key, TextEditingController controller) {
    final isSelected = _selectedAnswer == key;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opsi $key *',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Tulis opsi $key...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 84,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedAnswer = key;
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: isSelected
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFF3F4F6),
                  foregroundColor: isSelected
                      ? Colors.white
                      : const Color(0xFF6B7280),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isSelected ? '✓ Kunci' : 'Set Kunci'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
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

  String _buildStoredQuestion(String text, String mapel) {
    return '[${mapel.trim()}] ${text.trim()}';
  }

  _ParsedQuestion _parseStoredQuestion(String raw) {
    final match = RegExp(r'^\[(.+?)\]\s*(.*)$').firstMatch(raw.trim());
    if (match == null) {
      return _ParsedQuestion(
        mapel: _mapelOptions.first,
        questionText: raw.trim(),
      );
    }

    final mapel = match.group(1)?.trim() ?? _mapelOptions.first;
    final question = match.group(2)?.trim() ?? '';

    return _ParsedQuestion(
      mapel: mapel.isEmpty ? _mapelOptions.first : mapel,
      questionText: question,
    );
  }
}

class _ParsedQuestion {
  final String mapel;
  final String questionText;

  const _ParsedQuestion({required this.mapel, required this.questionText});
}
