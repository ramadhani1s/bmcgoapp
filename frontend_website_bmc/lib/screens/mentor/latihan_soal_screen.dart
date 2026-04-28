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

  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _jumlahSoalController = TextEditingController(
    text: '1',
  );
  final TextEditingController _durasiController = TextEditingController(
    text: '20',
  );
  final TextEditingController _jadwalController = TextEditingController();
  final List<_QuestionDraft> _drafts = <_QuestionDraft>[];

  final List<String> _mapelOptions = const [
    'Matematika',
    'Fisika',
    'Kimia',
    'Biologi',
    'Bahasa Indonesia',
    'Bahasa Inggris',
  ];

  String _selectedMapel = 'Matematika';

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
    _loadItems();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _jumlahSoalController.dispose();
    _durasiController.dispose();
    _jadwalController.dispose();
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

  void _openCreateForm() {
    _syncDraftCount(1);

    setState(() {
      _showForm = true;
      _editingItem = null;
      _selectedMapel = _mapelOptions.first;
      _judulController.text = '';
      _jumlahSoalController.text = '1';
      _durasiController.text = '20';
      _jadwalController.text = '';
      _drafts.first.reset();
    });
  }

  void _openEditForm(SoalLatihan item) {
    final parsed = _parseStoredQuestion(item.pertanyaan);
    _syncDraftCount(1);

    _drafts.first
      ..questionController.text = parsed.questionText
      ..optionAController.text = item.pilihanA
      ..optionBController.text = item.pilihanB
      ..optionCController.text = item.pilihanC
      ..optionDController.text = item.pilihanD
      ..selectedAnswer = item.jawaban.toUpperCase();

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
              'Judul Latihan *',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _judulController,
              decoration: InputDecoration(
                hintText: 'Contoh: Latihan Matematika Bab 1',
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _jumlahSoalController,
                    keyboardType: TextInputType.number,
                    enabled: _editingItem == null,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Soal *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      if (_editingItem != null) {
                        return;
                      }
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
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
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
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
                            _jumlahSoalController.text = '${_drafts.length}';
                          },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah Kolom Soal'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Maksimal 20 soal',
                    style: const TextStyle(
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
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
          onSelected: (_) {
            setState(() {
              draft.selectedAnswer = key;
            });
          },
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
