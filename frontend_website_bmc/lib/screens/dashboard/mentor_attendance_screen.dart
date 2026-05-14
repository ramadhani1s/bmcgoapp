import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/attendance_service.dart';
import '../../core/theme/app_colors.dart';

class MentorAttendanceScreen extends StatefulWidget {
  const MentorAttendanceScreen({super.key});

  @override
  State<MentorAttendanceScreen> createState() => _MentorAttendanceScreenState();
}

class _MentorAttendanceScreenState extends State<MentorAttendanceScreen> {
  bool _isLoading = true;
  bool _isStarting = false;
  bool _showToken = false;
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _summary;
  List<dynamic> _records = const [];
  Timer? _countdownTimer;
  Timer? _refreshTimer;
  Duration _hadirRemaining = Duration.zero;
  Duration _terlambatRemaining = Duration.zero;

  // use shared AppColors

  @override
  void initState() {
    super.initState();
    _loadActiveSession();
    _startTimers();
  }

  @override
  void dispose() {
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

    _refreshTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      _refreshLiveSessionData();
    });
  }

  void _updateCountdown() {
    final session = _session;
    if (session == null) {
      if (_hadirRemaining != Duration.zero ||
          _terlambatRemaining != Duration.zero) {
        setState(() {
          _hadirRemaining = Duration.zero;
          _terlambatRemaining = Duration.zero;
        });
      }
      return;
    }

    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final hadirDeadlineUnix = _readUnixSeconds(
      session['hadir_deadline_unix'],
      fallbackIso: session['hadir_deadline']?.toString(),
    );
    final terlambatDeadlineUnix = _readUnixSeconds(
      session['terlambat_deadline_unix'],
      fallbackIso: session['terlambat_deadline']?.toString(),
    );

    final nextHadir = Duration(
      milliseconds: (hadirDeadlineUnix * 1000) - nowMillis,
    );
    final nextTerlambat = Duration(
      milliseconds: (terlambatDeadlineUnix * 1000) - nowMillis,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _hadirRemaining = nextHadir.isNegative ? Duration.zero : nextHadir;
      _terlambatRemaining = nextTerlambat.isNegative
          ? Duration.zero
          : nextTerlambat;
    });
  }

  Future<void> _refreshLiveSessionData() async {
    if (!mounted) {
      return;
    }

    final active = await AttendanceService.getActiveSession();
    if (!mounted || active['success'] != true) {
      return;
    }

    final latest = active['session'] as Map<String, dynamic>?;
    if (latest == null) {
      setState(() {
        _session = null;
        _summary = null;
        _records = const [];
        _showToken = false;
      });
      _updateCountdown();
      return;
    }

    final latestId = (latest['id'] as num?)?.toInt();

    setState(() {
      _session = latest;
    });
    _updateCountdown();

    if (latestId != null) {
      await _loadSummary(latestId);
    }
  }

  Future<void> _loadActiveSession() async {
    setState(() {
      _isLoading = true;
    });

    final active = await AttendanceService.getActiveSession();

    if (!mounted) {
      return;
    }

    if (active['success'] == true && active['session'] != null) {
      final session = active['session'] as Map<String, dynamic>;
      setState(() {
        _session = session;
      });
      _updateCountdown();

      await _loadSummary((session['id'] as num?)?.toInt());
    } else {
      setState(() {
        _session = null;
        _summary = null;
        _records = const [];
        _showToken = false;
      });
      _updateCountdown();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadSummary(int? sessionId) async {
    if (sessionId == null) {
      return;
    }

    final result = await AttendanceService.getSessionSummary(sessionId);
    if (!mounted || result['success'] != true) {
      return;
    }

    setState(() {
      _summary = result['summary'] as Map<String, dynamic>?;
      _records = (result['records'] as List<dynamic>? ?? const []);
    });
  }

  Future<void> _startAttendance() async {
    final classController = TextEditingController();
    final subjectController = TextEditingController();

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Mulai Absensi Kelas',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: classController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kelas',
                    hintText: 'Contoh: Kelas 12 IPA A',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Mata Pelajaran (opsional)',
                    hintText: 'Contoh: Matematika',
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Mulai'),
            ),
          ],
        );
      },
    );

    if (proceed != true) {
      return;
    }

    setState(() {
      _isStarting = true;
    });

    final result = await AttendanceService.startSession(
      className: classController.text,
      subject: subjectController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isStarting = false;
    });

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (result['message'] ?? 'Gagal memulai absensi').toString(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _loadActiveSession();

    if (mounted) {
      setState(() {
        _showToken = true;
      });
    }

    if (!mounted) {
      return;
    }

    final token = (result['token'] ?? '').toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sesi dimulai. Token: $token'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'hadir':
        return AppColors.success;
      case 'terlambat':
        return AppColors.warning;
      case 'tidak_hadir':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

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

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int _readUnixSeconds(dynamic unixValue, {String? fallbackIso}) {
    final fromUnix = int.tryParse((unixValue ?? '').toString());
    if (fromUnix != null && fromUnix > 0) {
      return fromUnix;
    }

    if (fallbackIso != null && fallbackIso.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(fallbackIso.trim());
      if (parsed != null) {
        return parsed.toUtc().millisecondsSinceEpoch ~/ 1000;
      }
    }

    return DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  }

  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.accentBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBlue.withAlpha((0.15 * 255).round()),
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
                const Text(
                  'Absensi Kelas Mentor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola kehadiran dan rekap absensi siswa',
                  style: TextStyle(
                    color: Colors.white.withAlpha((0.9 * 255).round()),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          const Icon(Icons.assignment_turned_in, color: Colors.white, size: 64),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Absensi Kelas Mentor'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadActiveSession,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 20),
                  _buildToolbar(),
                  const SizedBox(height: 16),
                  if (_summary != null) ...[
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 740;
                        final children = [
                          _buildSummaryCard(
                            'Hadir',
                            _summary!['hadir'] ?? 0,
                            const Color(0xFF16A34A),
                          ),
                          _buildSummaryCard(
                            'Terlambat',
                            _summary!['terlambat'] ?? 0,
                            const Color(0xFFE67E22),
                          ),
                          _buildSummaryCard(
                            'Tidak Hadir',
                            _summary!['tidak_hadir'] ?? 0,
                            const Color(0xFFDC2626),
                          ),
                          _buildSummaryCard(
                            'Total Masuk',
                            _summary!['total_masuk'] ?? 0,
                            const Color(0xFF1D4ED8),
                          ),
                        ];

                        if (isWide) {
                          return GridView.count(
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            shrinkWrap: true,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.7,
                            children: children,
                          );
                        }

                        return Column(
                          children: children
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: item,
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    'Daftar Kehadiran Siswa',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.softBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(15, 23, 42, 0.04),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _records.isEmpty
                        ? const Text(
                            'Belum ada siswa yang mengisi token absensi.',
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Nama')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Waktu Input')),
                              ],
                              rows: _records.map((item) {
                                final status = (item['status'] ?? '-')
                                    .toString();
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text((item['nama'] ?? '-').toString()),
                                    ),
                                    DataCell(
                                      Text((item['email'] ?? '-').toString()),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(
                                            status,
                                          ).withAlpha((0.14 * 255).round()),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(_formatDate(item['submitted_at'])),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mulai Absensi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Klik tombol di kanan untuk memulai sesi absensi baru.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 46,
            width: 180,
            child: ElevatedButton.icon(
              onPressed: _isStarting ? null : _startAttendance,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(_isStarting ? 'Memulai...' : 'Mulai Absensi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
