import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/tryout_service.dart';
import '../../widgets/tryout/question_card.dart';
import '../../widgets/tryout/question_nav_popup.dart';
import 'tryout_submit_confirm.dart';
import 'tryout_result_dashboard.dart';

class TryOutExamScreen extends StatefulWidget {
  final Map<String, dynamic> package;
  const TryOutExamScreen({super.key, required this.package});

  @override
  State<TryOutExamScreen> createState() => _TryOutExamScreenState();
}

class _TryOutExamScreenState extends State<TryOutExamScreen> {
  List<Map<String, dynamic>> _questions = [];
  int _index = 0;
  final Map<int, String> _answers = {};
  final Set<int> _flagged = {};
  Timer? _timer;
  int _remaining = 150 * 60; // 150 minutes default

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final id = widget.package['id'] is int ? widget.package['id'] as int : int.tryParse('${widget.package['id']}') ?? 0;
    final list = await TryOutService.getQuestions(id);
    if (list.isEmpty) {
      setState(() {
        _questions = List.generate(150, (i) => {
          'id': i + 1,
          'nomor': i + 1,
          'pertanyaan': 'Soal contoh nomor ${i + 1}',
          'options': ['A','B','C','D'],
          'jawaban': 'A',
          'materi': 'Umum'
        });
      });
    } else {
      setState(() => _questions = list);
    }
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
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _selectAnswer(String opt) {
    setState(() => _answers[_index] = opt);
  }

  void _toggleFlag() {
    setState(() {
      if (_flagged.contains(_index)) _flagged.remove(_index); else _flagged.add(_index);
    });
  }

  void _openNav() async {
    final selected = await showDialog<int>(context: context, builder: (_) => QuestionNavPopup(questions: _questions, flagged: _flagged));
    if (selected != null) setState(() => _index = selected);
  }

  void _onSubmitPressed() async {
    final ok = await Navigator.push(context, MaterialPageRoute(builder: (_) => TryOutSubmitConfirm(answered: _answers.length, total: _questions.length)));
    if (ok == true) _finishExam();
  }

  void _onAutoSubmit() {
    _finishExam();
  }

  Future<void> _finishExam() async {
    _timer?.cancel();
    // compute simple stats
    final total = _questions.length;
    int correct = 0;
    for (var i = 0; i < total; i++) {
      final q = _questions[i];
      final ans = _answers[i];
      if (ans != null && ans == (q['jawaban'] ?? q['answer'])) correct++;
    }
    final score = ((correct / total) * 100).round();
    final id = widget.package['id'] is int ? widget.package['id'] as int : int.tryParse('${widget.package['id']}') ?? 0;
    final resp = await TryOutService.submitResult(id, _answers);
    if (!mounted) return;
    Map<String, dynamic> serverData = {};
    if (resp['success'] == true && resp['data'] != null) serverData = resp['data'] as Map<String, dynamic>;
    final resultPayload = {
      'score': serverData['score'] ?? score,
      'total': serverData['total'] ?? total,
      'correct': serverData['correct'] ?? correct,
      'accuracy': serverData['accuracy'] ?? (total == 0 ? 0 : (correct / total * 100)),
      'by_materi': serverData['by_materi'] ?? {},
    };
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TryOutResultDashboard(result: resultPayload, questions: _questions, answers: _answers)));
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions.isEmpty ? null : _questions[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text('Try Out - ${widget.package['judul'] ?? ''}'),
        backgroundColor: const Color(0xFFFF7070),
        actions: [
          Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(_formatTime(_remaining)))),
        ],
      ),
      body: q == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7070)))
          : Column(
              children: [
                Expanded(child: QuestionCard(question: q, selected: _answers[_index], onSelect: _selectAnswer)),
                Row(
                  children: [
                    IconButton(icon: Icon(_flagged.contains(_index) ? Icons.flag : Icons.outlined_flag), onPressed: _toggleFlag),
                    IconButton(icon: const Icon(Icons.list), onPressed: _openNav),
                    const Spacer(),
                    TextButton(onPressed: _onSubmitPressed, child: const Text('Submit'))
                  ],
                )
              ],
            ),
    );
  }
}
