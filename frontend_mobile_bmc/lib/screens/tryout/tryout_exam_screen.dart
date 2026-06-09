import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/tryout_service.dart';
import 'tryout_result_dashboard.dart';

class TryOutExamScreen extends StatefulWidget {
  final Map<String, dynamic> package;
  const TryOutExamScreen({super.key, required this.package});

  @override
  State<TryOutExamScreen> createState() => _TryOutExamScreenState();
}

class _TryOutExamScreenState extends State<TryOutExamScreen> {
  static const Color _accent = Color(0xFFFF7070);
  static const Color _background = Color(0xFFF7EEEF);
  
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  final Set<int> _flagged = {};
  Timer? _timer;
  int _remaining = 0;
  bool _isLoading = true;
  bool _showNavigasi = false;

  @override
  void initState() {
    super.initState();
    _remaining = (widget.package['durasi'] as int? ?? 150) * 60;
    _loadQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final id = widget.package['id'] as int;
    final list = await TryOutService.getQuestions(id);
    if (!mounted) return;
    setState(() {
      _questions = list;
      _isLoading = false;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) {
        _timer?.cancel();
        _onAutoSubmit();
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  String _formatTime(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showSelesaiDialog() {
    final dijawab = _answers.length;
    final total = _questions.length;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Selesai Try Out?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Anda telah menjawab $dijawab dari $total soal.\nMasih ada ${total - dijawab} soal yang belum dijawab.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: _accent)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finishExam();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF12B892)),
            child: const Text('Ya, Selesai', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onAutoSubmit() {
    _finishExam();
  }

  Future<void> _finishExam() async {
    _timer?.cancel();
    final id = widget.package['id'] as int;
    
    // Konversi key int ke String karena backend expects map[string]string (tapi di TryOutService dikonversi otomatis)
    final resp = await TryOutService.submitResult(id, _answers);
    
    if (!mounted) return;
    
    // Langsung pindah ke hasil, fetch updated data inside result dashboard
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TryOutResultDashboard(package: widget.package, result: resp['data'] ?? {})));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: _background, body: Center(child: CircularProgressIndicator(color: _accent)));
    if (_questions.isEmpty) return Scaffold(backgroundColor: _background, body: Center(child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Kembali'))));

    final q = _questions[_currentIndex];
    final qId = q['id'] as int;
    final options = {
      'A': q['pilihan_a'] as String? ?? '',
      'B': q['pilihan_b'] as String? ?? '',
      'C': q['pilihan_c'] as String? ?? '',
      'D': q['pilihan_d'] as String? ?? '',
      'E': q['pilihan_e'] as String? ?? '',
    };
    
    int dijawab = _answers.length;
    int ragu = _flagged.length;
    int belum = _questions.length - dijawab;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((q['kategori'] as String? ?? '').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: _accent.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                            child: Text(q['kategori'], style: const TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Soal Nomor ${_currentIndex + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Text(q['pertanyaan'] ?? '', style: const TextStyle(fontSize: 15, height: 1.5)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...options.entries.where((e) => e.value.isNotEmpty).map((entry) {
                          final isSelected = _answers[qId] == entry.key;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _answers[qId] = entry.key;
                              if (_currentIndex < _questions.length - 1) {
                                Future.delayed(const Duration(milliseconds: 300), () => setState(() => _currentIndex++));
                              }
                            }),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFFEFEF) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? _accent : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isSelected ? _accent : const Color(0xFFF0F0F0),
                                    child: Text(entry.key, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 14))),
                                  if (isSelected) const Icon(Icons.check_circle_rounded, color: _accent, size: 20),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() {
                            if (_flagged.contains(qId)) _flagged.remove(qId);
                            else _flagged.add(qId);
                          }),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _flagged.contains(qId) ? const Color(0xFFFFF8E1) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _flagged.contains(qId) ? const Color(0xFFF5A623) : Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bookmark_border_rounded, color: _flagged.contains(qId) ? const Color(0xFFF5A623) : Colors.grey.shade600, size: 20),
                                const SizedBox(width: 8),
                                Text('Tandai Ragu-ragu', style: TextStyle(color: _flagged.contains(qId) ? const Color(0xFFF5A623) : Colors.grey.shade600, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
                _buildBottomNav(dijawab, ragu, belum),
              ],
            ),
            if (_showNavigasi) _buildNavigasiSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final progress = (_currentIndex + 1) / _questions.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.package['judul'] ?? 'Try Out', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Soal ${_currentIndex + 1} dari ${_questions.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(_formatTime(_remaining), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(int dijawab, int ragu, int belum) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatusIndicator('$dijawab', 'Terjawab', const Color(0xFFE3FBF4), const Color(0xFF12B892))),
              const SizedBox(width: 8),
              Expanded(child: _buildStatusIndicator('$ragu', 'Ragu-ragu', const Color(0xFFFFF8E1), const Color(0xFFF5A623))),
              const SizedBox(width: 8),
              Expanded(child: _buildStatusIndicator('$belum', 'Belum', const Color(0xFFFFEFEF), _accent)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _currentIndex > 0 ? const Color(0xFFF0F0F0) : Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.chevron_left_rounded, color: _currentIndex > 0 ? Colors.black87 : Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showNavigasi = !_showNavigasi),
                  icon: const Icon(Icons.grid_view_rounded, size: 18),
                  label: const Text('Navigasi Soal', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _currentIndex < _questions.length - 1 ? () => setState(() => _currentIndex++) : _showSelesaiDialog,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(14)),
                  child: Icon(_currentIndex < _questions.length - 1 ? Icons.chevron_right_rounded : Icons.check_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String val, String lbl, Color bg, Color txt) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(val, style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(lbl, style: TextStyle(color: txt, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildNavigasiSheet() {
    return GestureDetector(
      onTap: () => setState(() => _showNavigasi = false),
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Navigasi Soal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => setState(() => _showNavigasi = false),
                        child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildLegendDot(const Color(0xFF12B892), 'Terjawab'), const SizedBox(width: 12),
                      _buildLegendDot(const Color(0xFFF5A623), 'Ragu-ragu'), const SizedBox(width: 12),
                      _buildLegendDot(const Color(0xFFE0E0E0), 'Belum'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 400,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final qId = _questions[index]['id'] as int;
                        final dijawab = _answers.containsKey(qId);
                        final ragu = _flagged.contains(qId);
                        final isCurrent = index == _currentIndex;

                        Color bg = const Color(0xFFF0F0F0);
                        Color textColor = Colors.grey.shade700;
                        Color border = Colors.transparent;

                        if (isCurrent) {
                          border = _accent;
                          if (!dijawab && !ragu) bg = Colors.white;
                        }

                        if (ragu) { bg = const Color(0xFFFFF8E1); textColor = const Color(0xFFF5A623); }
                        else if (dijawab) { bg = const Color(0xFFE3FBF4); textColor = const Color(0xFF12B892); }

                        return GestureDetector(
                          onTap: () => setState(() { _currentIndex = index; _showNavigasi = false; }),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(12),
                              border: border != Colors.transparent ? Border.all(color: border, width: 2) : null,
                            ),
                            child: Center(child: Text('${index + 1}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
                          ),
                        );
                      },
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

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

