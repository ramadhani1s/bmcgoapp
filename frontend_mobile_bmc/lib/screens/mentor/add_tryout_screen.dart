import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/models/mentor_competition_item.dart';
import 'package:frontend_mobile_bmc/services/mentor_competition_service.dart';

class AddTryoutScreen extends StatefulWidget {
  const AddTryoutScreen({super.key, this.initialItem});

  final MentorCompetitionItem? initialItem;

  @override
  State<AddTryoutScreen> createState() => _AddTryoutScreenState();
}

class _AddTryoutScreenState extends State<AddTryoutScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFD1D5DB);
  static const Color _accent = Color(0xFF2563EB);

  final _namaController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _durasiController = TextEditingController();

  final List<String> _kelasOptions = const ['Kelas 10', 'Kelas 11', 'Kelas 12'];

  final Map<String, TextEditingController> _categoryControllers = {
    'PU': TextEditingController(),
    'PPU': TextEditingController(),
    'PBM': TextEditingController(),
    'PK': TextEditingController(),
    'LBI': TextEditingController(),
  };

  bool _isSaving = false;
  String _selectedKelas = 'Kelas 12';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialItem;
    if (initial == null) {
      _durasiController.text = '180';
      return;
    }

    _namaController.text = initial.title;
    _tanggalController.text = initial.scheduleLabel;
    _durasiController.text = initial.durationLabel;
    _selectedKelas = _kelasOptions.contains(initial.classLevel)
        ? initial.classLevel
        : _kelasOptions.last;
    for (final entry in _categoryControllers.entries) {
      entry.value.text = (initial.categoryQuestions[entry.key] ?? 0).toString();
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tanggalController.dispose();
    _durasiController.dispose();
    for (final c in _categoryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _field(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
    );
  }

  Future<void> _save() async {
    final title = _namaController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama try out wajib diisi.')),
      );
      return;
    }

    final categoryMap = <String, int>{};
    var total = 0;
    for (final entry in _categoryControllers.entries) {
      final value = int.tryParse(entry.value.text.trim()) ?? 0;
      categoryMap[entry.key] = value;
      total += value;
    }

    setState(() {
      _isSaving = true;
    });

    final item = MentorCompetitionItem(
      id:
          widget.initialItem?.id ??
          'tryout_${DateTime.now().millisecondsSinceEpoch}',
      type: 'tryout',
      classLevel: _selectedKelas,
      title: title,
      subject: 'Try Out Online',
      totalQuestions: total,
      durationLabel: _durasiController.text.trim().isEmpty
          ? '180'
          : _durasiController.text.trim(),
      scheduleLabel: _tanggalController.text.trim(),
      isPublished: true,
      createdAt: widget.initialItem?.createdAt ?? DateTime.now(),
      categoryQuestions: categoryMap,
    );

    await MentorCompetitionService.createOrUpdate(item);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              color: Colors.white,
              child: Row(
                children: const [
                  Icon(Icons.menu, size: 20),
                  SizedBox(width: 10),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF4F46E5),
                    child: Text(
                      'M',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.notifications_none_outlined, size: 20),
                  SizedBox(width: 10),
                  Icon(Icons.person_outline, size: 20),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.arrow_back_ios_new,
                        size: 13,
                        color: _textMuted,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Kembali',
                        style: TextStyle(color: _textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.initialItem == null
                        ? 'Buat Try Out Baru'
                        : 'Edit Try Out',
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Isi form di bawah untuk membuat try out',
                    style: TextStyle(color: _textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nama Try Out',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _namaController,
                          decoration: _field(
                            'Contoh: Try Out UTBK 2026 Batch 1',
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Kelas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedKelas,
                          decoration: _field('Pilih Kelas'),
                          items: _kelasOptions
                              .map(
                                (e) => DropdownMenuItem<String>(
                                  value: e,
                                  child: Text(e),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _selectedKelas = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tanggal Pelaksanaan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _tanggalController,
                                    decoration: _field('mm/dd/yyyy'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Waktu (menit)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _durasiController,
                                    keyboardType: TextInputType.number,
                                    decoration: _field('180'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Jumlah Soal per Kategori',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final entry in _categoryControllers.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: entry.value,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: _field('0'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: _accent),
                      icon: const Icon(
                        Icons.save_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text(
                        'Simpan',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
