import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/services/attendance_service.dart';
import 'package:frontend_mobile_bmc/widgets/attendance/attendance_filter_card.dart';
import 'package:frontend_mobile_bmc/widgets/attendance/attendance_history_item.dart';
import 'package:frontend_mobile_bmc/widgets/attendance/attendance_result_card.dart';
import 'package:frontend_mobile_bmc/widgets/attendance/attendance_token_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingHistory = true;
  Map<String, dynamic>? _latestResult;
  List<dynamic> _history = const [];
  String _selectedClass = 'Semua Kelas';
  DateTime? _selectedDate;
  Timer? _countdownTimer;
  Timer? _refreshTimer;
  Map<String, dynamic>? _activeSession;
  DateTime? _localDeadline;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadActiveSession();
    _startTimers();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadActiveSession();
    });
  }

  void _updateCountdown() {
    final localDeadline = _localDeadline;
    if (localDeadline == null) {
      if (_remainingTime != Duration.zero) {
        setState(() {
          _remainingTime = Duration.zero;
        });
      }
      return;
    }

    final remaining = localDeadline.difference(DateTime.now());

    if (!mounted) return;

    setState(() {
      _remainingTime = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  Future<void> _loadActiveSession() async {
    final response = await AttendanceService.getActiveSessionForSiswa();
    if (!mounted) return;

    if (response['success'] == true && response['session'] != null) {
      final session = response['session'] as Map<String, dynamic>;
      final serverTimeUnix = response['server_time_unix'] as int? ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      final deadlineUnix = session['hadir_deadline_unix'] as int? ?? 0;
      
      final clientNow = DateTime.now().millisecondsSinceEpoch;
      final serverOffsetMillis = (deadlineUnix - serverTimeUnix) * 1000;

      setState(() {
        _activeSession = session;
        _localDeadline = DateTime.fromMillisecondsSinceEpoch(clientNow + serverOffsetMillis);
      });
      _updateCountdown();
    } else {
      setState(() {
        _activeSession = null;
        _localDeadline = null;
        _remainingTime = Duration.zero;
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    final history = await AttendanceService.getHistory(
      className: _selectedClass == 'Semua Kelas' ? null : _selectedClass,
      date: _selectedDate,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _history = history;
      _isLoadingHistory = false;

      if (_selectedClass != 'Semua Kelas') {
        final hasSelectedClass = _classOptions.contains(_selectedClass);
        if (!hasSelectedClass) {
          _selectedClass = 'Semua Kelas';
        }
      }
    });
  }

  List<String> get _classOptions {
    final set = <String>{'Semua Kelas'};
    for (final item in _history) {
      final className = (item['class_name'] ?? '').toString().trim();
      if (className.isNotEmpty) {
        set.add(className);
      }
    }
    return set.toList();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(selected.year, selected.month, selected.day);
    });
    await _loadHistory();
  }

  void _clearFilters() {
    setState(() {
      _selectedClass = 'Semua Kelas';
      _selectedDate = null;
    });
    _loadHistory();
  }

  Future<void> _submitToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token absensi wajib diisi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await AttendanceService.submitToken(token);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result['message'] ?? 'Gagal kirim token absensi').toString()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _latestResult = result['attendance'] as Map<String, dynamic>?;
    });

    _tokenController.clear();
    await _loadHistory();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text((result['message'] ?? 'Absensi berhasil').toString()),
        backgroundColor: const Color(0xFF22C55E),
      ),
    );
  }

  // status color helper was removed because it's not referenced.

  String _formatDate(dynamic value) {
    final parsed = DateTime.tryParse((value ?? '').toString());
    if (parsed == null) {
      return '-';
    }

    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _formatFilterDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateLabel = _selectedDate == null
        ? 'Pilih Tanggal'
        : _formatFilterDate(_selectedDate!);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Kelas'),
        actions: [
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AttendanceTokenCard(
                controller: _tokenController,
                isSubmitting: _isSubmitting,
                onSubmit: _submitToken,
                activeSession: _activeSession,
                remainingTime: _remainingTime,
              ),
              if (_latestResult != null) ...[
                const SizedBox(height: 14),
                AttendanceResultCard(
                  status: (_latestResult!['status'] ?? '-').toString(),
                  className: (_latestResult!['class_name'] ?? '-').toString(),
                  subject: (_latestResult!['subject'] ?? '-').toString(),
                  submittedAt: _formatDate(_latestResult!['submitted_at']),
                ),
              ],
              const SizedBox(height: 14),
              const Text(
                'Riwayat Absensi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              AttendanceFilterCard(
                classOptions: _classOptions,
                selectedClass: _selectedClass,
                selectedDateLabel: selectedDateLabel,
                onClassChanged: (value) async {
                  setState(() {
                    _selectedClass = value;
                  });
                  await _loadHistory();
                },
                onPickDate: _pickDate,
                onReset: _clearFilters,
              ),
              if (_isLoadingHistory)
                const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ))
              else if (_history.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('Belum ada data absensi.'),
                )
              else
                ..._history.map((item) {
                  return AttendanceHistoryItem(
                    className: (item['class_name'] ?? '-').toString(),
                    subject: (item['subject'] ?? '-').toString(),
                    submittedAt: _formatDate(item['submitted_at']),
                    status: (item['status'] ?? '-').toString(),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
