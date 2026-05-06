import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/models/mentor_competition_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TryoutQuestionManagementScreen extends StatefulWidget {
  const TryoutQuestionManagementScreen({super.key, required this.item});

  final MentorCompetitionItem item;

  @override
  State<TryoutQuestionManagementScreen> createState() =>
      _TryoutQuestionManagementScreenState();
}

class _TryoutQuestionManagementScreenState
    extends State<TryoutQuestionManagementScreen> {
  static const Color _bg = Color(0xFFF3F4F6);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFD1D5DB);
  static const Color _accent = Color(0xFF2563EB);

  final _questionController = TextEditingController();
  final _pembahasanController = TextEditingController();
  final Map<String, TextEditingController> _optionControllers = {
    'A': TextEditingController(),
    'B': TextEditingController(),
    'C': TextEditingController(),
    'D': TextEditingController(),
    'E': TextEditingController(),
  };

  late final List<String> _categories;
  late String _activeCategory;
  String _answerKey = 'A';
  Map<String, List<Map<String, dynamic>>> _data = {};

  String get _storageKey => 'tryout_questions_${widget.item.id}';

  @override
  void initState() {
    super.initState();
    _categories = widget.item.categoryQuestions.keys.toList();
    if (_categories.isEmpty) {
      _categories.addAll(['PU', 'PPU', 'PBM', 'PK', 'LBI']);
    }
    _activeCategory = _categories.first;
    _loadData();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _pembahasanController.dispose();
    for (final c in _optionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() {
        _data = {for (final c in _categories) c: <Map<String, dynamic>>[]};
      });
      return;
    }

    final decoded = jsonDecode(raw);
    final parsed = <String, List<Map<String, dynamic>>>{};
    if (decoded is Map<String, dynamic>) {
      for (final key in decoded.keys) {
        final list = decoded[key];
        if (list is List) {
          parsed[key] = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _data = {
        for (final c in _categories) c: parsed[c] ?? <Map<String, dynamic>>[],
      };
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_data));
  }

  void _addQuestion() {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      return;
    }

    final options = <String, String>{};
    for (final entry in _optionControllers.entries) {
      options[entry.key] = entry.value.text.trim();
    }

    final next = [...(_data[_activeCategory] ?? <Map<String, dynamic>>[])];
    next.add({
      'question': question,
      'options': options,
      'answerKey': _answerKey,
      'pembahasan': _pembahasanController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });

    setState(() {
      _data[_activeCategory] = next;
      _questionController.clear();
      _pembahasanController.clear();
      for (final c in _optionControllers.values) {
        c.clear();
      }
      _answerKey = 'A';
    });

    _saveData();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Soal berhasil ditambahkan.')));
  }

  int _count(String category) => (_data[category] ?? const []).length;

  @override
  Widget build(BuildContext context) {
    final totalTarget = widget.item.totalQuestions <= 0
        ? 0
        : widget.item.totalQuestions;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'Kembali',
                    style: TextStyle(color: _textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Text(
                    widget.item.title,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_data.values.fold<int>(0, (sum, list) => sum + list.length)}/$totalTarget soal dibuat',
                    style: const TextStyle(color: _textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((c) {
                      final selected = c == _activeCategory;
                      final target = widget.item.categoryQuestions[c] ?? 0;
                      return ChoiceChip(
                        label: Text('$c (${_count(c)}/$target)'),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _activeCategory = c;
                          });
                        },
                        selectedColor: const Color(0xFFDBEAFE),
                      );
                    }).toList(),
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
                          'Tambah Soal Baru',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pertanyaan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _questionController,
                          maxLines: 3,
                          decoration: _decoration(
                            'Masukkan pertanyaan soal...',
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Pilihan Jawaban',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        for (final entry in _optionControllers.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: entry.value,
                                    decoration: _decoration(
                                      'Isi opsi ${entry.key}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text(
                              'Jawaban Benar: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            DropdownButton<String>(
                              value: _answerKey,
                              items: const ['A', 'B', 'C', 'D', 'E']
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _answerKey = value;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pembahasan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _pembahasanController,
                          maxLines: 2,
                          decoration: _decoration(
                            'Masukkan pembahasan soal...',
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                            ),
                            child: const Text(
                              'Tambah Soal',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        Text(
                          'Daftar Soal $_activeCategory',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_count(_activeCategory)} soal',
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if ((_data[_activeCategory] ?? const []).isEmpty)
                          const Text(
                            'Belum ada soal untuk kategori ini',
                            style: TextStyle(color: _textMuted, fontSize: 12),
                          )
                        else
                          for (final q in _data[_activeCategory]!)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _border),
                                ),
                                child: Text(
                                  q['question']?.toString() ?? '-',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
    );
  }

  InputDecoration _decoration(String hint) {
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
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
    );
  }
}
