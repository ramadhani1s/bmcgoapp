import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../routes/app_routes.dart';
import '../../services/attendance_service.dart';
import '../../services/jadwal_pembelajaran_service.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/mentor_sidebar_shell.dart';
import 'jadwal_pembelajaran_screen.dart';
import 'mentor_olimpiade_screen.dart';
import '../mentor/materi_pembelajaran_screen.dart';

class MentorAttendanceScreen extends StatefulWidget {
  const MentorAttendanceScreen({super.key});

  @override
  State<MentorAttendanceScreen> createState() => _MentorAttendanceScreenState();
}

class _MentorAttendanceScreenState extends State<MentorAttendanceScreen> {
  bool _isLoading = true;
  bool _isStarting = false;
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _summary;
  List<dynamic> _records = const [];
  Timer? _countdownTimer;
  Timer? _refreshTimer;
  Duration _hadirRemaining = Duration.zero;
  Duration _terlambatRemaining = Duration.zero;

  List<String> _mentorClasses = [];
  List<String> _mentorSubjects = [];

  // use shared AppColors

  @override
  void initState() {
    super.initState();
    _loadActiveSession();
    _loadMentorSchedules();
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

  Future<void> _loadMentorSchedules() async {
    try {
      final res = await JadwalService.getMentorJadwalList();
      final classes = <String>{};
      final subjects = <String>{};
      for (final s in res) {
        final classLevel = s['class_level']?.toString();
        if (classLevel != null && classLevel.isNotEmpty && classLevel != 'null') {
          classes.add(classLevel.trim());
        }
        final mapel = s['mata_pelajaran']?.toString();
        if (mapel != null && mapel.isNotEmpty && mapel != 'null') {
          subjects.add(mapel.trim());
        }
      }
      if (mounted) {
        setState(() {
          _mentorClasses = classes.toList()..sort();
          _mentorSubjects = subjects.toList()..sort();
        });
      }
    } catch (e) {
      debugPrint('Error loading mentor schedules: $e');
    }
  }

  Future<void> _startAttendance() async {
    final classController = TextEditingController(
      text: _mentorClasses.isNotEmpty ? _mentorClasses.first : '',
    );
    final subjectController = TextEditingController(
      text: _mentorSubjects.isNotEmpty ? _mentorSubjects.first : '',
    );

    final resultData = await showDialog<Map<String, String>>(
      context: context,
      barrierColor: Colors.black.withAlpha(107),
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setStateDialog) {
          final titleStyle = GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          );
          final labelFont = GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF374151),
          );

          final screenHeight = MediaQuery.of(ctx).size.height;

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            contentPadding: EdgeInsets.zero,
            content: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 460,
                maxWidth: 460,
                maxHeight: screenHeight * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Styled Header (Gradient Biru)
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(41),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.play_circle_outline_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mulai Absensi Kelas',
                                style: titleStyle,
                              ),
                              Text(
                                'Atur detail sesi absensi baru Anda',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Fields Container
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label Kelas
                        Text('Nama Kelas', style: labelFont),
                        const SizedBox(height: 6),
                        TextField(
                          controller: classController,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Masukkan nama kelas (e.g. 10 IPA)',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Label Mapel
                        Text('Mata Pelajaran', style: labelFont),
                        const SizedBox(height: 6),
                        TextField(
                          controller: subjectController,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Masukkan mata pelajaran (e.g. Matematika)',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions / Footer Buttons
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF374151),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            side: const BorderSide(color: Color(0xFFD8E1EE)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final cls = classController.text.trim();
                            final subj = subjectController.text.trim();
                            if (cls.isEmpty) {
                              ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                const SnackBar(
                                  content: Text('Nama kelas wajib diisi'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            Navigator.of(ctx).pop({
                              'class_name': cls,
                              'subject': subj,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Mulai'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (resultData == null) {
      return;
    }

    setState(() {
      _isStarting = true;
    });

    final result = await AttendanceService.startSession(
      className: resultData['class_name']!,
      subject: resultData['subject']!,
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

  void _onSidebarMenuTap(String title) {
    if (title == 'Dashboard') {
      Navigator.pushReplacementNamed(context, AppRoutes.mentorDashboard);
      return;
    }
    if (title == 'Jadwal Mengajar') {
      Navigator.pushReplacement(
        context,
        InstantPageRoute(
          child: const JadwalPembelajaranScreen(mentorView: true),
        ),
      );
      return;
    }
    if (title == 'Absensi Kelas') {
      return;
    }
    if (title == 'Soal Latihan') {
      Navigator.pushReplacementNamed(context, AppRoutes.mentorExercise);
      return;
    }
    if (title == 'Try Out') {
      Navigator.pushReplacementNamed(context, AppRoutes.mentorTryout);
      return;
    }
    if (title == 'Materi Pembelajaran') {
      Navigator.pushReplacement(
        context,
        InstantPageRoute(
          child: const MateriPembelajaranScreen(initialClass: null),
        ),
      );
      return;
    }
    if (title == 'Olimpiade Akademik') {
      Navigator.pushReplacement(
        context,
        InstantPageRoute(child: const MentorOlimpiadeScreen()),
      );
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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
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

  Future<void> _copyTokenToClipboard() async {
    final token = (_session?['token'] ?? '').toString().trim();
    if (token.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Token absensi disalin'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  Widget _buildActiveSessionCard() {
    final session = _session;
    if (session == null) {
      return Container(
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
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sesi Absensi Aktif',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text(
              'Belum ada sesi absensi yang berjalan. Token akan muncul di sini setelah mentor menekan Mulai Absensi.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    final token = (session['token'] ?? '').toString();
    final className = (session['class_name'] ?? '-').toString();
    final subject = (session['subject'] ?? '-').toString();
    final tokenVisible = token.isEmpty ? '------' : token;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sesi Absensi Aktif',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Token tetap tampil sampai sesi diganti atau selesai.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _copyTokenToClipboard,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Salin Token'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.softBorder),
            ),
            child: Text(
              tokenVisible,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: _hadirRemaining == Duration.zero ? Colors.red : AppColors.accentBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _hadirRemaining == Duration.zero
                      ? 'Waktu Absensi Habis'
                      : 'Sisa Waktu Absensi: ${_formatDuration(_hadirRemaining)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _hadirRemaining == Duration.zero ? Colors.red : AppColors.accentBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                'Kelas: $className',
                const Color(0xFFDBEAFE),
                const Color(0xFF1D4ED8),
              ),
              _chip(
                'Mapel: $subject',
                const Color(0xFFE0F2FE),
                const Color(0xFF0369A1),
              ),
              _chip(
                'Mulai: ${_formatDate(session['started_at'])}',
                const Color(0xFFF3F4F6),
                const Color(0xFF374151),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bgColor, Color fgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fgColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAttendanceRecordsTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
          ? const Text('Belum ada siswa yang mengisi token absensi.')
          : LayoutBuilder(
              builder: (context, tableConstraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: tableConstraints.maxWidth,
                    ),
                    child: DataTable(
                      columnSpacing: 22,
                      horizontalMargin: 12,
                      headingRowHeight: 40,
                      dataRowMinHeight: 44,
                      dataRowMaxHeight: 52,
                      columns: const [
                        DataColumn(label: Text('Nama')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Waktu Input')),
                        DataColumn(label: Text('Laporan')),
                      ],
                      rows: _records.map((item) {
                        final status = (item['status'] ?? '-').toString();
                        final siswaId = item['siswa_id'];
                        return DataRow(
                           cells: [
                            DataCell(Text((item['nama'] ?? '-').toString())),
                            DataCell(Text((item['email'] ?? '-').toString())),
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
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(_formatDate(item['submitted_at']))),
                            DataCell(
                              Center(
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Color(0xFFDC2626),
                                    size: 20,
                                  ),
                                  tooltip: "Unduh Laporan PDF",
                                  onPressed: () {
                                    _downloadStudentPDF(siswaId);
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _downloadStudentPDF(dynamic siswaId) async {
    if (siswaId == null) return;
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse('${AuthService.baseUrl}/api/mentor/absensi/download-pdf/$siswaId?token=$token');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Gagal mengunduh PDF"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MentorSidebarShell(
      activeMenuTitle: 'Absensi Kelas',
      onMenuTap: _onSidebarMenuTap,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
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
                    _buildActiveSessionCard(),
                    const SizedBox(height: 16),
                    if (_summary != null) ...[
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
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 2.5,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildAttendanceRecordsTable(),
                  ],
                ),
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
