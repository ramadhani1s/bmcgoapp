import 'package:flutter/material.dart';

import '../../models/soal_latihan.dart';
import '../../services/latihan_soal_service.dart';

class LatihanSoalViewScreen extends StatefulWidget {
  final String mapel;
  final String latihanTitle;

  const LatihanSoalViewScreen({
    super.key,
    required this.mapel,
    required this.latihanTitle,
  });

  @override
  State<LatihanSoalViewScreen> createState() => _LatihanSoalViewScreenState();
}

class _LatihanSoalViewScreenState extends State<LatihanSoalViewScreen> {
  bool _isLoading = true;
  List<SoalLatihan> _items = [];
  int _activeIndex = 0;
  bool _showPembahasan = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await LatihanSoalService.getSoalLatihan();
    if (!mounted) return;
    setState(() {
      _items = items
          .where((item) => item.pertanyaan.contains('[${widget.mapel}]'))
          .toList();
      _isLoading = false;
      if (_activeIndex >= _items.length) {
        _activeIndex = 0;
      }
    });
  }

  _ParsedQuestion _parseQuestion(String raw) {
    final match = RegExp(r'^\[(.+?)\]\s*(.*)$').firstMatch(raw.trim());
    if (match == null) {
      return _ParsedQuestion(mapel: widget.mapel, questionText: raw.trim());
    }
    return _ParsedQuestion(
      mapel: match.group(1)?.trim() ?? widget.mapel,
      questionText: match.group(2)?.trim() ?? raw.trim(),
    );
  }

  void _previous() {
    if (_items.isEmpty) return;
    setState(() {
      _activeIndex = (_activeIndex - 1).clamp(0, _items.length - 1);
      _showPembahasan = false;
    });
  }

  void _next() {
    if (_items.isEmpty) return;
    setState(() {
      _activeIndex = (_activeIndex + 1).clamp(0, _items.length - 1);
      _showPembahasan = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = _items.isNotEmpty ? _items[_activeIndex] : null;
    final parsed = active != null ? _parseQuestion(active.pertanyaan) : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 1,
        title: Text('Lihat Soal - ${widget.latihanTitle}'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.latihanTitle,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _pill(
                                    widget.mapel,
                                    const Color(0xFFDBEAFE),
                                    const Color(0xFF2563EB),
                                  ),
                                  _pill(
                                    '${_items.length} soal',
                                    const Color(0xFFF3F4F6),
                                    const Color(0xFF6B7280),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Navigasi Soal',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: List.generate(_items.length, (
                                          index,
                                        ) {
                                          final isActive =
                                              index == _activeIndex;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: GestureDetector(
                                              onTap: () => setState(() {
                                                _activeIndex = index;
                                                _showPembahasan = false;
                                              }),
                                              child: Container(
                                                width: 54,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? const Color(0xFF2563EB)
                                                      : const Color(0xFFF3F4F6),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: TextStyle(
                                                      color: isActive
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF6B7280,
                                                            ),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _items.isEmpty
                                          ? 'Tidak ada soal'
                                          : 'Soal aktif: ${_activeIndex + 1} / ${_items.length}',
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (active == null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.visibility_off_outlined,
                                  size: 48,
                                  color: Color(0xFFD1D5DB),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Belum ada soal untuk ditampilkan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2563EB),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Soal Nomor ${_activeIndex + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.18,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          'Kunci: ${active.jawaban.toUpperCase()}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        parsed?.questionText ??
                                            active.pertanyaan,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF1F2937),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _optionTile(
                                        'A',
                                        active.pilihanA,
                                        active.jawaban,
                                      ),
                                      const SizedBox(height: 10),
                                      _optionTile(
                                        'B',
                                        active.pilihanB,
                                        active.jawaban,
                                      ),
                                      const SizedBox(height: 10),
                                      _optionTile(
                                        'C',
                                        active.pilihanC,
                                        active.jawaban,
                                      ),
                                      const SizedBox(height: 10),
                                      _optionTile(
                                        'D',
                                        active.pilihanD,
                                        active.jawaban,
                                      ),
                                      const SizedBox(height: 14),
                                      InkWell(
                                        onTap: () => setState(
                                          () => _showPembahasan =
                                              !_showPembahasan,
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE5E7EB),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Expanded(
                                                child: Text(
                                                  'Pembahasan',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                _showPembahasan
                                                    ? Icons.keyboard_arrow_up
                                                    : Icons.keyboard_arrow_down,
                                                color: const Color(0xFF6B7280),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (_showPembahasan) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          active.pembahasan.isEmpty
                                              ? 'Belum ada pembahasan.'
                                              : active.pembahasan,
                                          style: const TextStyle(
                                            color: Color(0xFF374151),
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: _activeIndex == 0
                                                  ? null
                                                  : _previous,
                                              icon: const Icon(
                                                Icons.chevron_left,
                                              ),
                                              label: const Text('Sebelumnya'),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed:
                                                  _activeIndex >=
                                                      _items.length - 1
                                                  ? null
                                                  : _next,
                                              icon: const Icon(
                                                Icons.chevron_right,
                                              ),
                                              label: const Text('Selanjutnya'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF2563EB,
                                                ),
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
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
                ),
              ),
      ),
    );
  }

  Widget _optionTile(String key, String text, String answer) {
    final isAnswer = answer.toUpperCase() == key;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isAnswer ? const Color(0xFFECFDF3) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAnswer ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isAnswer
                  ? const Color(0xFF10B981)
                  : const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                key,
                style: TextStyle(
                  color: isAnswer ? Colors.white : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isAnswer
                    ? const Color(0xFF166534)
                    : const Color(0xFF374151),
                fontWeight: isAnswer ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          if (isAnswer)
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF10B981),
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color background, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ParsedQuestion {
  final String mapel;
  final String questionText;

  const _ParsedQuestion({required this.mapel, required this.questionText});
}
