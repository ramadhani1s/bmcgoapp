import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../models/admin_dashboard_data.dart';
import '../../services/admin_dashboard_service.dart';
import '../../services/auth_service.dart';
import '../../services/jadwal_pembelajaran_service.dart';
import 'paket_les_screen.dart';
import 'jadwal_pembelajaran_screen.dart';
import 'verifikasi_pendaftaran_screen.dart';
import 'pengumuman_screen.dart';
import 'admin_laporan_absensi_screen.dart';
import 'admin_kelola_alumni_screen.dart';
import '../mentor_management_screen.dart';
import '../../models/payment_verification_item.dart';
import '../../routes/app_routes.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, this.initialMenuTitle});

  final String? initialMenuTitle;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color _pageCream = Color(0xFFF1F4FA);
  static const Color _sidebarCream = Color(0xFFF8FAFD);
  static const Color _surfaceCream = Colors.white;
  static const Color _borderCream = Color(0xFFDDE4F0);
  static const Color _softBorderCream = Color(0xFFE9EFF8);

  User? _currentUser;
  bool _isProfileHovered = false;
  int _selectedMenuIndex = 0;
  String _selectedMenuTitle = 'Dashboard';
  AdminDashboardData? _summary;
  bool _isSummaryLoading = true;
  List<PaymentVerificationItem>? _quickPendingItems;
  bool _isQuickPendingLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<_ScheduleRow> _todayScheduleRows = [];
  int _todayScheduleCount = 0;
  int? _initialEditJadwalId;

  @override
  void initState() {
    super.initState();
    _applyInitialMenu();
    _loadUser();
    _loadSummary();
    _loadTodaySchedules();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyInitialMenu() {
    final initialTitle = widget.initialMenuTitle;
    if (initialTitle == null || initialTitle.isEmpty) {
      return;
    }

    final index = _menuItems.indexWhere((item) => item.title == initialTitle);
    if (index < 0) {
      return;
    }

    _selectedMenuIndex = index;
    _selectedMenuTitle = initialTitle;
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isSummaryLoading = true;
    });

    try {
      final summary = await AdminDashboardService.getSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSummaryLoading = false;
        });
      }
      // also refresh quick pending preview
      _loadQuickPending();
    }
  }

  Future<void> _loadQuickPending() async {
    setState(() {
      _isQuickPendingLoading = true;
    });
    try {
      final items =
          await AdminDashboardService.getPendingPaymentVerifications();
      if (!mounted) return;
      setState(() {
        _quickPendingItems = items;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _quickPendingItems = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isQuickPendingLoading = false;
        });
      }
    }
  }

  Future<void> _loadTodaySchedules() async {
    try {
      final todayName = _dayName(DateTime.now());
      final results = await Future.wait([
        JadwalService.getJadwalList(hari: todayName),
        JadwalService.getPaketList(),
        JadwalService.getMentorList(),
      ]);

      if (!mounted) return;

      final jadwalList = results[0];
      final paketList = results[1];
      final mentorList = results[2];

      String resolveClassName(Map<String, dynamic> j) {
        final classLevel = j['class_level']?.toString();
        if (classLevel != null && classLevel.isNotEmpty && classLevel != 'null') {
          if (classLevel.contains('Kelas')) return classLevel;
          return 'Kelas $classLevel';
        }
        final pId = j['paket_id'];
        for (final paket in paketList) {
          if (paket['id'] == pId) {
            final pkgClass = paket['class_level']?.toString();
            if (pkgClass != null && pkgClass.isNotEmpty && pkgClass != 'null') {
              if (pkgClass.contains('Kelas')) return pkgClass;
              return 'Kelas $pkgClass';
            }
            return (paket['nama_paket'] ?? paket['nama'] ?? '-').toString();
          }
        }
        return 'Kelas ${pId ?? '-'}';
      }

      String mentorName(dynamic mentorId) {
        for (final mentor in mentorList) {
          if (mentor['id'] == mentorId) {
            return (mentor['nama_mentor'] ?? mentor['nama'] ?? '-').toString();
          }
        }
        return 'Mentor ${mentorId ?? '-'}';
      }

      int toMinutes(String? hhmm) {
        if (hhmm == null || hhmm.isEmpty) return -1;
        final clean = hhmm.contains('T')
            ? (DateTime.tryParse(hhmm) != null
                  ? '${DateTime.parse(hhmm).hour.toString().padLeft(2, '0')}:${DateTime.parse(hhmm).minute.toString().padLeft(2, '0')}'
                  : hhmm)
            : hhmm;
        final parts = clean.split(':');
        if (parts.length < 2) return -1;
        final h = int.tryParse(parts[0]) ?? -1;
        final m = int.tryParse(parts[1]) ?? -1;
        if (h < 0 || m < 0) return -1;
        return (h * 60) + m;
      }

      String hhmm(dynamic value) {
        if (value == null) return '-';
        final text = value.toString();
        if (text.isEmpty) return '-';
        if (text.contains('T')) {
          final parsed = DateTime.tryParse(text);
          if (parsed != null) {
            return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
          }
        }
        final parts = text.split(':');
        if (parts.length >= 2) {
          return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
        }
        return text;
      }

      final now = DateTime.now();
      final nowMinutes = (now.hour * 60) + now.minute;

      final mappedRows = jadwalList.map((jadwal) {
        final start = hhmm(jadwal['jam_mulai']);
        final end = hhmm(jadwal['jam_selesai']);
        final startMinutes = toMinutes(start);
        final endMinutes = toMinutes(end);

        String status = 'Akan Datang';
        if (startMinutes >= 0 && endMinutes >= 0) {
          if (nowMinutes >= startMinutes && nowMinutes <= endMinutes) {
            status = 'Berlangsung';
          } else if (nowMinutes > endMinutes) {
            status = 'Selesai';
          }
        }

        final rawId = jadwal['id'];
        final parsedId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;
        return _ScheduleRow(
          id: parsedId,
          time: '$start - $end',
          className: resolveClassName(jadwal),
          subject: (jadwal['mata_pelajaran'] ?? '-').toString(),
          mentor: mentorName(jadwal['mentor_id']),
          room: (jadwal['ruang'] ?? '-').toString(),
          status: status,
        );
      }).toList();

      setState(() {
        _todayScheduleRows = mappedRows;
        _todayScheduleCount = mappedRows.length;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _todayScheduleRows = [];
        _todayScheduleCount = 0;
      });
    }
  }

  Future<void> _deleteTodaySchedule(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: const Text(
          'Hapus Jadwal?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah Anda yakin ingin menghapus jadwal pembelajaran ini?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.warning, color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aksi ini tidak bisa dibatalkan. Data absensi dan rekaman kehadiran terkait juga akan dihapus secara permanen dari sistem.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4B5563),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await JadwalService.deleteJadwal(id);
      if (mounted) {
        final success = result['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? (success ? 'Jadwal berhasil dihapus' : 'Gagal menghapus jadwal')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        _loadTodaySchedules();
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _confirmAndLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        actionsPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 32,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  children: const [
                    Text(
                      'Keluar dari Halaman Admin?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Apakah Anda yakin ingin keluar dari halaman admin? Anda harus login kembali untuk mengakses panel kontrol.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: const Color(0xFF4B5563),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Keluar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  void _onMenuTap(int index, _SideMenuItem item) {
    setState(() {
      _selectedMenuIndex = index;
      _selectedMenuTitle = item.title;
      if (item.title != 'Kelola Jadwal') {
        _initialEditJadwalId = null;
      }
    });

    if (item.title == 'Dashboard') {
      _loadSummary();
      _loadTodaySchedules();
    }
  }

  List<_SideMenuItem> get _menuItems => const [
    _SideMenuItem('Dashboard', Icons.grid_view_rounded),
    _SideMenuItem('Verifikasi Pendaftaran', Icons.fact_check_outlined),
    _SideMenuItem('Kelola Mentor', Icons.groups_2_outlined),
    _SideMenuItem('Kelola Jadwal', Icons.event_note_outlined),
    _SideMenuItem(
      'Laporan Absensi',
      Icons.assignment_turned_in_outlined,
      route: '/admin-laporan-absensi',
    ),
    _SideMenuItem('Kelola Pengumuman', Icons.campaign_outlined),
    _SideMenuItem(
      'Kelola Paket Les',
      Icons.school_outlined,
      route: '/paket-les',
    ),
    _SideMenuItem('Kelola Profil Alumni', Icons.badge_outlined),
  ];

  List<_StatCardData> get _stats => [
    _StatCardData(
      title: 'Menunggu Verifikasi',
      value: (_summary?.waitingVerifications ?? 0).toString(),
      subtitle: 'Pendaftaran Siswa Baru',
      color: const Color(0xFFFF7A00),
      backgroundColor: const Color(0xFFF6EFE7),
      icon: Icons.person_add_alt_1,
    ),
    _StatCardData(
      title: 'Jadwal Hari Ini',
      value: _todayScheduleCount.toString(),
      subtitle: 'Kelas Aktif',
      color: const Color(0xFF2E7BEF),
      backgroundColor: const Color(0xFFF0F5FF),
      icon: Icons.calendar_month,
    ),
    _StatCardData(
      title: 'Siswa Aktif',
      value: (_summary?.activeStudents ?? 0).toString(),
      subtitle: 'Total Siswa Terdaftar',
      color: const Color(0xFF17BF63),
      backgroundColor: const Color(0xFFEDF8F0),
      icon: Icons.groups,
    ),
  ];

  // ignore: unused_element
  List<_PendingVerificationRow> get _pendingRows {
    final items = _summary?.pendingItems ?? const <DashboardPendingItem>[];
    if (items.isEmpty) {
      return const [];
    }

    final rows = items
        .map(
          (item) => _PendingVerificationRow(
            transactionId: '',
            name: item.studentName,
            school: item.schoolName,
            className: item.className,
            date:
                '${item.date.day.toString().padLeft(2, '0')} ${_monthName(item.date.month).substring(0, 3)} ${item.date.year}',
            status: item.status,
          ),
        )
        .toList();

    if (_searchQuery.trim().isEmpty) {
      return rows;
    }

    final q = _searchQuery.toLowerCase();
    return rows
        .where(
          (row) =>
              row.name.toLowerCase().contains(q) ||
              row.school.toLowerCase().contains(q) ||
              row.className.toLowerCase().contains(q) ||
              row.status.toLowerCase().contains(q),
        )
        .toList();
  }

  List<_ScheduleRow> get _scheduleRows {
    if (_searchQuery.trim().isEmpty) {
      return _todayScheduleRows;
    }

    final q = _searchQuery.toLowerCase();
    return _todayScheduleRows
        .where(
          (row) =>
              row.className.toLowerCase().contains(q) ||
              row.subject.toLowerCase().contains(q) ||
              row.mentor.toLowerCase().contains(q) ||
              row.room.toLowerCase().contains(q) ||
              row.status.toLowerCase().contains(q) ||
              row.time.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _pageCream,
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                    child: SingleChildScrollView(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedMenuTitle == 'Kelola Mentor')
                          const MentorManagementScreen(
                            embeddedInDashboard: true,
                          )
                        else if (_selectedMenuTitle == 'Kelola Jadwal')
                          JadwalPembelajaranScreen(
                            embeddedInDashboard: true,
                            initialEditJadwalId: _initialEditJadwalId,
                          )
                        else if (_selectedMenuTitle == 'Kelola Paket Les')
                          const PaketLesScreen()
                        else if (_selectedMenuTitle == 'Kelola Pengumuman')
                          PengumumanScreen()
                        else if (_selectedMenuTitle == 'Verifikasi Pendaftaran')
                          const VerifikasiPendaftaranScreen()
                        else if (_selectedMenuTitle == 'Laporan Absensi')
                          const AdminLaporanAbsensiScreen()
                        else if (_selectedMenuTitle == 'Kelola Profil Alumni')
                          const AdminKelolaAlumniScreen(
                            embeddedInDashboard: true,
                          )
                        else ...[
                          _buildTopBar(),
                          const SizedBox(height: 18),
                          if (_isSummaryLoading)
                            const LinearProgressIndicator(minHeight: 2),
                          if (_isSummaryLoading) const SizedBox(height: 8),
                          _buildStatsRow(),
                          const SizedBox(height: 18),
                          _buildPendingVerificationCard(),
                          const SizedBox(height: 14),
                          _buildScheduleCard(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  String _dayName(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[date.weekday - 1];
  }

  String _formatIndoDate(DateTime date) {
    return '${_dayName(date)}, ${date.day} ${_monthName(date.month)} ${date.year}';
  }

  // Helper methods untuk status label di quick pending items
  String _getStatusLabelDashboard(PaymentVerificationItem item) {
    if (item.isVerified) {
      return '✓ Disetujui';
    }
    if (item.status == 'success') {
      return '⏳ Menunggu';
    }
    return '✗ Ditolak';
  }

  Color _getStatusColorDashboard(PaymentVerificationItem item) {
    if (item.isVerified) {
      return const Color(0xFF16A34A); // Hijau
    }
    if (item.status == 'success') {
      return const Color(0xFFF97316); // Orange
    }
    return const Color(0xFFEF4444); // Merah
  }

  Color _getStatusBgColorDashboard(PaymentVerificationItem item) {
    if (item.isVerified) {
      return const Color(0xFFECFDF3);
    }
    if (item.status == 'success') {
      return const Color(0xFFFFF7ED);
    }
    return const Color(0xFFFEF2F2);
  }

  Widget _buildSidebar() {
    return Container(
      width: 214,
      decoration: BoxDecoration(
        color: _sidebarCream,
        border: const Border(
          right: BorderSide(color: _borderCream),
          top: BorderSide(color: _borderCream),
          bottom: BorderSide(color: _borderCream),
          left: BorderSide(color: Color(0xFF2A8CF4), width: 2),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  // Lokasi logo sidebar admin.
                  child: Image.asset('assets/images/BMC .png'),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BMC GrowUp',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF1E2A3E),
                        ),
                      ),
                      Text(
                        'Bintang Muda Center',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6D7B93),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MENU UTAMA',
                style: TextStyle(
                  color: Color(0xFF9AA4B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _menuItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final selected = index == _selectedMenuIndex;
                return InkWell(
                  onTap: () => _onMenuTap(index, item),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2A58F2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 15,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF8290A6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF4B5972),
                              fontSize: 12.5,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
            child: InkWell(
              onTap: _confirmAndLogout,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 15,
                      color: Color(0xFF9CA5B5),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Keluar',
                      style: TextStyle(color: Color(0xFF8E96A8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final today = DateTime.now();

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EDF7)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Selamat Datang, Admin!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Berikut adalah ringkasan informasi terkini dari sistem manajemen BMC - ${_formatIndoDate(today)}.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF7D8797),
                size: 22,
              ),
              Positioned(
                right: 1,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4057),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {
              setState(() {
                _isProfileHovered = true;
              });
            },
            onExit: (_) {
              setState(() {
                _isProfileHovered = false;
              });
            },
            child: InkWell(
              onTap: () {
                Navigator.of(context)
                    .pushNamed(AppRoutes.adminProfile)
                    .then((_) {
                  _loadUser();
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _isProfileHovered
                      ? const Color(0xFFF1F5FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isProfileHovered ? 38 : 32,
                      height: _isProfileHovered ? 38 : 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A58F2),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2A58F2).withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _currentUser?.nama.isNotEmpty == true
                            ? _currentUser!.nama.substring(0, 2).toUpperCase()
                            : 'AD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: _isProfileHovered
                                ? const Color(0xFF2A58F2)
                                : const Color(0xFF27344B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          child: Text(
                            _currentUser?.nama ?? 'Administrator BMC',
                          ),
                        ),
                        Text(
                          _currentUser?.roleName == 'Unknown'
                              ? 'Administrator'
                              : _currentUser!.roleName,
                          style: const TextStyle(
                            color: Color(0xFF99A4B5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: _stats
          .map(
            (e) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: e.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: e.color.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: e.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.subtitle,
                            style: const TextStyle(
                              color: Color(0xFF8290A6),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: e.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(e.icon, color: e.color, size: 28),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPendingVerificationCard() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceCream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EDF7)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.05),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pendaftaran Menunggu Verifikasi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_summary?.waitingVerifications ?? 0} pendaftaran belum diverifikasi',
                        style: const TextStyle(
                          color: Color(0xFFDBEAFE),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final index = _menuItems.indexWhere(
                      (item) => item.title == 'Verifikasi Pendaftaran',
                    );

                    if (index != -1) {
                      setState(() {
                        _selectedMenuIndex = index;
                        _selectedMenuTitle = 'Verifikasi Pendaftaran';
                      });
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Lihat Detail'),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: const _TableHeaderRow(
              columns: [
                'NAMA SISWA',
                'SEKOLAH',
                'KELAS',
                'TANGGAL',
                'STATUS',
                'AKSI',
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                if (_isQuickPendingLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if ((_quickPendingItems == null) ||
                    _quickPendingItems!.isEmpty)
                  const _EmptyTableRow(
                    message: 'Belum ada pendaftaran yang menunggu verifikasi.',
                  )
                else
                  for (final item in _quickPendingItems!.take(5))
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFF0E6D8)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.studentName,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.schoolName,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.className,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${item.createdAt.day.toString().padLeft(2, '0')} ${_monthName(item.createdAt.month).substring(0, 3)} ${item.createdAt.year}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusBgColorDashboard(item),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColorDashboard(
                                    item,
                                  ).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                _getStatusLabelDashboard(item),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _getStatusColorDashboard(item),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                ElevatedButton(
                                  onPressed: item.isVerified
                                      ? null
                                      : () async {
                                          try {
                                            await AdminDashboardService.approvePaymentVerification(
                                              item.transactionId,
                                            );
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Pembayaran disetujui',
                                                ),
                                              ),
                                            );
                                            await _loadSummary();
                                            await _loadQuickPending();
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Gagal approve: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(52, 26),
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(fontSize: 11),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Setuju'),
                                ),
                                const SizedBox(width: 6),
                                OutlinedButton(
                                  onPressed: item.isVerified
                                      ? null
                                      : () async {
                                          try {
                                            await AdminDashboardService.rejectPaymentVerification(
                                              item.transactionId,
                                            );
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Pembayaran ditolak',
                                                ),
                                              ),
                                            );
                                            await _loadSummary();
                                            await _loadQuickPending();
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Gagal reject: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(70, 26),
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(
                                      color: Color(0xFFEF4444),
                                    ),
                                    textStyle: const TextStyle(fontSize: 11),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Tolak'),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: () {
                                    final index = _menuItems.indexWhere(
                                      (item) =>
                                          item.title ==
                                          'Verifikasi Pendaftaran',
                                    );

                                    if (index != -1) {
                                      setState(() {
                                        _selectedMenuIndex = index;
                                        _selectedMenuTitle =
                                            'Verifikasi Pendaftaran';
                                      });
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: Color(0xFF3B82F6),
                                  ),
                                  tooltip: 'Lihat detail',
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
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceCream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EDF7)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.05),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jadwal Belajar Hari Ini',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatIndoDate(DateTime.now())} - total $_todayScheduleCount sesi',
                        style: const TextStyle(
                          color: Color(0xFFDBEAFE),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final index = _menuItems.indexWhere(
                      (item) => item.title == 'Kelola Jadwal',
                    );
                    if (index >= 0) {
                      _onMenuTap(index, _menuItems[index]);
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(
                      (0.15 * 255).round(),
                    ),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Lihat semua'),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: const _TableHeaderRow(
              columns: [
                'WAKTU',
                'KELAS',
                'MATA PELAJARAN',
                'MENTOR',
                'RUANG',
                'STATUS',
                'AKSI',
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                if (_scheduleRows.isEmpty)
                  const _EmptyTableRow(
                    message: 'Belum ada jadwal belajar untuk hari ini.',
                  )
                else
                  for (final row in _scheduleRows)
                    _ScheduleItemRow(
                      row: row,
                       onEdit: () {
                        setState(() {
                          _initialEditJadwalId = row.id;
                        });
                        final index = _menuItems.indexWhere(
                          (item) => item.title == 'Kelola Jadwal',
                        );
                        if (index >= 0) {
                          _onMenuTap(index, _menuItems[index]);
                        }
                      },
                      onDelete: () => _deleteTodaySchedule(row.id),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideMenuItem {
  const _SideMenuItem(this.title, this.icon, {this.route});

  final String title;
  final IconData icon;
  final String? route;
}

class _StatCardData {
  const _StatCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final Color backgroundColor;
  final IconData icon;
}

class _PendingVerificationRow {
  const _PendingVerificationRow({
    required this.transactionId,
    required this.name,
    required this.school,
    required this.className,
    required this.date,
    required this.status,
  });

  final String transactionId;
  final String name;
  final String school;
  final String className;
  final String date;
  final String status;
}

class _EmptyTableRow extends StatelessWidget {
  const _EmptyTableRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0E6D8))),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF94A0B4),
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _ScheduleRow {
  const _ScheduleRow({
    required this.id,
    required this.time,
    required this.className,
    required this.subject,
    required this.mentor,
    required this.room,
    required this.status,
  });

  final int id;
  final String time;
  final String className;
  final String subject;
  final String mentor;
  final String room;
  final String status;
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.columns});

  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: columns
          .map(
            (c) => Expanded(
              child: Text(
                c,
                style: const TextStyle(
                  color: Color(0xFF9AA4B6),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ignore: unused_element
class _PendingItemRow extends StatelessWidget {
  const _PendingItemRow({
    required this.row,
    required this.onApprove,
    required this.onReject,
  });

  final _PendingVerificationRow row;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  Color _statusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return const Color(0xFF16A34A);
      case 'Ditolak':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFFF8A00);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0E6D8))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(row.name, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: Text(row.school, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Text(row.className, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(child: Text(row.date, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(row.status).withAlpha((0.14 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                row.status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _statusColor(row.status),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(52, 26),
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 11),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Setuju'),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(70, 26),
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    textStyle: const TextStyle(fontSize: 11),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Tidak Setuju'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleItemRow extends StatelessWidget {
  const _ScheduleItemRow({
    required this.row,
    required this.onEdit,
    required this.onDelete,
  });

  final _ScheduleRow row;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = row.status == 'Berlangsung';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0E6D8))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(row.time, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  row.className,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(row.subject, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Text(row.mentor, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Text(
              row.room,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A94A8)),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFE6EEFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  row.status,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF15803D)
                        : const Color(0xFF2B58E8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF4F82FF)),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFEF4444)),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
