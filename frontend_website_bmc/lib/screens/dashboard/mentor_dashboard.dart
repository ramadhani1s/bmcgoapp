import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_observer.dart';
import '../../services/auth_service.dart';
import '../../services/jadwal_pembelajaran_service.dart';
import '../../services/mentor_competition_service.dart';
import '../../services/latihan_management_service.dart';
import '../../services/latihan_soal_service.dart';
import '../../models/mentor_competition_item.dart';
import 'jadwal_pembelajaran_screen.dart';
import 'mentor_attendance_screen.dart';
import 'mentor_olimpiade_screen.dart';
import '../mentor/materi_pembelajaran_screen.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> with RouteAware {
  User? _currentUser;
  String _activeMenuTitle = 'Dashboard';
  bool _loadingDashboardCards = true;
  List<Map<String, dynamic>> _recentSchedules = [];
  List<Map<String, dynamic>> _paketList = [];
  List<MentorCompetitionItem> _recentTryouts = [];
  List<MentorCompetitionItem> _recentOlimpiades = [];
  final String _selectedClass = 'Semua Kelas';

  static const Color _sidebarBg = Color(0xFFF8FAFD);
  static const Color _sidebarBorder = Color(0xFFDDE4F0);
  static const Color _sidebarActive = Color(0xFF2A58F2);

  final List<_SidebarMenuItem> _menuItems = const [
    _SidebarMenuItem(title: 'Dashboard', icon: Icons.home_outlined),
    _SidebarMenuItem(
      title: 'Jadwal Mengajar',
      icon: Icons.calendar_month_outlined,
    ),
    _SidebarMenuItem(title: 'Absensi Kelas', icon: Icons.fact_check_outlined),
    _SidebarMenuItem(title: 'Soal Latihan', icon: Icons.menu_book_outlined),
    _SidebarMenuItem(title: 'Try Out', icon: Icons.rocket_launch_outlined),
    _SidebarMenuItem(
      title: 'Materi Pembelajaran',
      icon: Icons.video_library_outlined,
    ),
    _SidebarMenuItem(
      title: 'Olimpiade Akademik',
      icon: Icons.emoji_events_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped and this route shows again.
    setState(() => _activeMenuTitle = 'Dashboard');
    _loadStats();
    _loadDashboardCards();
  }

  Future<T> _safeLoad<T>(Future<T> future, T fallback) async {
    try {
      return await future;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _loadDashboardCards() async {
    final mentorId = _currentUser?.id;
    if (mentorId == null) return;

    setState(() => _loadingDashboardCards = true);
    final results = await Future.wait([
      _safeLoad(
        JadwalService.getMentorJadwalList(),
        <Map<String, dynamic>>[],
      ),
      _safeLoad(
        JadwalService.getPaketList(),
        <Map<String, dynamic>>[],
      ),
      _safeLoad(
        MentorCompetitionService.getByType('tryout'),
        <MentorCompetitionItem>[],
      ),
      _safeLoad(
        MentorCompetitionService.getByType('olimpiade'),
        <MentorCompetitionItem>[],
      ),
    ]);

    final schedules = results[0] as List<Map<String, dynamic>>;
    final pakets = results[1] as List<Map<String, dynamic>>;
    final tryouts = results[2] as List<MentorCompetitionItem>;
    final olimpiades = results[3] as List<MentorCompetitionItem>;

    if (!mounted) return;
    setState(() {
      _recentSchedules = schedules.take(3).toList();
      _paketList = pakets;
      _recentTryouts = tryouts.take(3).toList();
      _recentOlimpiades = olimpiades.take(2).toList();
      _loadingDashboardCards = false;
    });
  }

  Future<void> _loadStats() async {
    // Stats are no longer displayed on the dashboard; keep method for
    // compatibility but avoid storing unused fields.
    try {
      await LatihanManagementService.getLatihan();
      await LatihanSoalService.getSoalLatihan();
      await MentorCompetitionService.getByType('tryout');
      await MentorCompetitionService.getByType('olimpiade');
    } catch (_) {
      // ignore
    }
  }

  String _pickValue(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '-',
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return fallback;
  }

  String _timeToString(dynamic value) {
    if (value == null) return '';
    final text = value.toString();
    if (text.isEmpty) return '';

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

  String _packageLabel(Map<String, dynamic> paket) {
    return (paket['nama_paket'] ?? paket['nama'] ?? 'Paket').toString();
  }

  Map<String, dynamic>? _findPaketById(int? id) {
    if (id == null) return null;
    for (final paket in _paketList) {
      if (paket['id'] == id) return paket;
    }
    return null;
  }

  String _resolveKelasFromJadwal(Map<String, dynamic> j) {
    final classLevel = j['class_level']?.toString();
    if (classLevel != null && classLevel.isNotEmpty && classLevel != 'null') {
      if (classLevel.contains('Kelas')) return classLevel;
      return 'Kelas $classLevel';
    }
    final paketId = j['paket_id'] as int?;
    if (paketId == null) return 'Kelas';
    final paket = _findPaketById(paketId);
    if (paket == null) return 'Kelas';
    return _packageLabel(paket);
  }

  String _formatScheduleTime(Map<String, dynamic> item) {
    final rawStart = _pickValue(item, [
      'jam_mulai',
      'start_time',
      'jamAwal',
      'time_start',
    ]);
    final rawEnd = _pickValue(item, [
      'jam_selesai',
      'end_time',
      'jamAkhir',
      'time_end',
    ]);
    if (rawStart == '-' && rawEnd == '-') {
      return _pickValue(item, ['jam', 'waktu'], fallback: 'Jadwal tersedia');
    }
    final start = rawStart == '-' ? '-' : _timeToString(rawStart);
    final end = rawEnd == '-' ? '-' : _timeToString(rawEnd);
    return '$start${end == '-' ? '' : ' - $end'}';
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notifikasi'),
        content: const Text('Tidak ada notifikasi baru.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _openProfilePage() async {
    await Navigator.of(context).pushNamed(AppRoutes.mentorProfile);
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() => _currentUser = user);
    if (user != null) {
      _loadDashboardCards();
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _confirmAndLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari halaman mentor?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  String _buildFormattedDate() {
    final now = DateTime.now();
    const dayNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const monthNames = [
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

    final day = dayNames[now.weekday - 1];
    final month = monthNames[now.month - 1];
    return '$day, ${now.day} $month ${now.year}';
  }

  Future<void> _onMenuTap(String title) async {
    setState(() => _activeMenuTitle = title);
    if (title == 'Dashboard') return;

    final navigator = Navigator.of(context);

    if (title == 'Jadwal Mengajar') {
      await navigator.push(
        InstantPageRoute(
          child: const JadwalPembelajaranScreen(mentorView: true),
        ),
      );
      await _loadStats();
      return;
    }
    if (title == 'Absensi Kelas') {
      await navigator.push(
        InstantPageRoute(child: const MentorAttendanceScreen()),
      );
      await _loadStats();
      return;
    }
    if (title == 'Soal Latihan') {
      await navigator.pushNamed(AppRoutes.mentorExercise);
      await _loadStats();
      return;
    }
    if (title == 'Try Out') {
      await navigator.pushNamed(AppRoutes.mentorTryout);
      await _loadStats();
      return;
    }
    if (title == 'Materi Pembelajaran') {
      await navigator.push(
        InstantPageRoute(
          child: MateriPembelajaranScreen(
            initialClass: _selectedClass == 'Semua Kelas'
                ? null
                : _selectedClass,
          ),
        ),
      );
      await _loadStats();
      return;
    }
    if (title == 'Olimpiade Akademik') {
      await navigator.push(
        InstantPageRoute(child: const MentorOlimpiadeScreen()),
      );
      await _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isMobile = MediaQuery.of(context).size.width < 820;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isMobile ? Drawer(child: _buildSidebar(forDrawer: true)) : null,
      body: SafeArea(
        child: isMobile
            ? _buildDashboardContent(isMobile: true)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebar(forDrawer: false),
                  Expanded(child: _buildDashboardContent(isMobile: false)),
                ],
              ),
      ),
    );
  }

  Widget _buildDashboardContent({required bool isMobile}) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 16,
        isMobile ? 6 : 0,
        isMobile ? 16 : 18,
        20,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDashboardHeader(isMobile),
              const SizedBox(height: 12),
              _buildHeroCard(),
              const SizedBox(height: 12),
              _buildTopPanels(),
              const SizedBox(height: 14),
              _buildOlimpiadeCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardHeader(bool isMobile) {
    final displayName = _currentUser?.nama ?? 'Mentor';
    final dateLabel = _buildFormattedDate();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          Builder(
            builder: (buttonContext) => IconButton(
              onPressed: () => Scaffold.of(buttonContext).openDrawer(),
              icon: const Icon(Icons.menu, color: Color(0xFF1F2937)),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard Mentor',
                style: TextStyle(
                  color: Color(0xFF1F3C88),
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  height: 1.0,
                ),
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  _buildHeaderChip(
                    icon: Icons.calendar_today_outlined,
                    label: dateLabel,
                    backgroundColor: const Color(0xFFDBEAFE),
                    foregroundColor: const Color(0xFF1D4ED8),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildNotificationButton(),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _openProfilePage,
          child: _buildProfileButton(displayName),
        ),
      ],
    );
  }

  Widget _buildTopActionButton(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF475569)),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildTopActionButton(
          Icons.notifications_none,
          onTap: _showNotifications,
        ),
        Positioned(
          right: 7,
          top: 7,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileButton(String displayName) {
    final displayNameSafe = displayName.isNotEmpty ? displayName : 'Mentor';
    final roleName = _currentUser?.roleName ?? 'Mentor';
    final initial = displayNameSafe[0].toUpperCase();

    return InkWell(
      onTap: _openProfilePage,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayNameSafe,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  roleName,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar({required bool forDrawer}) {
    return Container(
      width: forDrawer ? double.infinity : 232,
      decoration: const BoxDecoration(
        color: _sidebarBg,
        border: Border(right: BorderSide(color: _sidebarBorder)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Image.asset('assets/images/BMC .png'),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'BMC Mentor',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MENU UTAMA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: _menuItems.map((item) {
                final active = item.title == _activeMenuTitle;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: InkWell(
                    onTap: () {
                      if (forDrawer) Navigator.of(context).pop();
                      _onMenuTap(item.title);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: active ? _sidebarActive : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 15,
                            color: active
                                ? Colors.white
                                : const Color(0xFF8290A6),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF4B5972),
                                fontSize: 12.3,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, size: 16),
            title: const Text('Keluar', style: TextStyle(fontSize: 12.5)),
            onTap: _confirmAndLogout,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332557E4),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.08 * 255).round()),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.space_dashboard_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Aktivitas Mengajar Hari Ini',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pantau jadwal mengajar, kelola latihan siswa, serta akses informasi try out dan olimpiade akademik.',
                  style: TextStyle(
                    color: Color(0xFFD9E4FF),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPanels() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 960;
        final scheduleCard = _buildScheduleCard();
        final tryoutCard = _buildTryoutCard();

        if (stacked) {
          return Column(
            children: [scheduleCard, const SizedBox(height: 16), tryoutCard],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: scheduleCard),
            const SizedBox(width: 18),
            Expanded(child: tryoutCard),
          ],
        );
      },
    );
  }

  Widget _buildScheduleCard() {
    final filtered = _selectedClass == 'Semua Kelas'
        ? _recentSchedules
        : _recentSchedules.where((item) {
            final kelas = _resolveKelasFromJadwal(item);
            return kelas == _selectedClass;
          }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: const BoxDecoration(
              color: AppColors.accentBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal Mengajar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Jadwal kelas yang aktif hari ini',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFD9E4FF),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const JadwalPembelajaranScreen(mentorView: true),
                      ),
                    );
                    await _loadDashboardCards();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Lihat semua'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingDashboardCards)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_recentSchedules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 46,
                      color: Color(0xFFD1D5DB),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Belum ada jadwal mengajar.',
                      style: TextStyle(
                        color: Color(0xFF8B909A),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 46,
                      color: Color(0xFFD1D5DB),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Belum ada jadwal mengajar.',
                      style: TextStyle(
                        color: Color(0xFF8B909A),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: filtered
                  .map((item) => _buildScheduleRow(item))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTryoutCard() {
    final filtered = _selectedClass == 'Semua Kelas'
        ? _recentTryouts
        : _recentTryouts
              .where((item) => item.classLevel == _selectedClass)
              .toList();

    return _buildCompetitionCard(
      title: 'Try Out Terbaru',
      actionLabel: 'Kelola',
      onActionTap: () async {
        await Navigator.of(context).pushNamed(AppRoutes.mentorTryout);
        await _loadDashboardCards();
      },
      items: filtered,
      emptyLabel: 'Belum ada try out terbaru.',
      itemBuilder: (item) => _buildCompetitionRow(item),
      headerColor: AppColors.warning,
      backgroundColor: AppColors.surface,
      subtitle: 'Try out yang baru dipublikasikan',
    );
  }

  Widget _buildOlimpiadeCard() {
    final filtered = _selectedClass == 'Semua Kelas'
        ? _recentOlimpiades
        : _recentOlimpiades
              .where((item) => item.classLevel == _selectedClass)
              .toList();

    return _buildCompetitionCard(
      title: 'Olimpiade Akademik',
      actionLabel: 'Lihat semua',
      onActionTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MentorOlimpiadeScreen()),
        );
        await _loadDashboardCards();
      },
      items: filtered,
      emptyLabel: 'Belum ada olimpiade akademik.',
      itemBuilder: (item) => _buildOlimpiadeRow(item),
      headerColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      subtitle: 'Kompetisi akademik terbaru',
    );
  }

  Widget _buildScheduleRow(Map<String, dynamic> item) {
    final title = _pickValue(item, [
      'mata_pelajaran',
      'mapel',
      'subject',
      'judul',
      'nama',
    ], fallback: 'Jadwal');
    final kelas = _resolveKelasFromJadwal(item);
    final ruang = _pickValue(item, ['ruang', 'room'], fallback: 'Ruang');
    final time = _formatScheduleTime(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title — $kelas',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$time · $ruang',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blueLightBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Jadwal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitionCard<T>({
    required String title,
    required String actionLabel,
    required VoidCallback onActionTap,
    required List<T> items,
    required String emptyLabel,
    required Widget Function(T item) itemBuilder,
    required Color headerColor,
    required Color backgroundColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
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
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFD9E4FF),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onActionTap,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingDashboardCards)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 46,
                      color: Color(0xFFD1D5DB),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      emptyLabel,
                      style: const TextStyle(
                        color: Color(0xFF8B909A),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Column(children: items.map(itemBuilder).toList()),
        ],
      ),
    );
  }

  // ignore: unused_element
  List<String> _availableClasses() {
    // Normalize values: trim and deduplicate to avoid duplicate menu items
    final normalized = <String>{};

    for (final item in _recentSchedules) {
      final raw = _pickValue(item, [
        'kelas',
        'class_level',
        'class_name',
      ], fallback: '');
      final kelas = raw.trim();
      if (kelas.isNotEmpty) normalized.add(kelas);
    }

    for (final t in _recentTryouts) {
      final kelas = t.classLevel.trim();
      if (kelas.isNotEmpty) normalized.add(kelas);
    }

    for (final o in _recentOlimpiades) {
      final kelas = o.classLevel.trim();
      if (kelas.isNotEmpty) normalized.add(kelas);
    }

    // Ensure the default option exists and keep it at top
    normalized.removeWhere((s) => s.trim().isEmpty);
    final list = normalized.toList()..sort();
    list.removeWhere((s) => s == 'Semua Kelas');
    return ['Semua Kelas', ...list];
  }

  Widget _buildHeaderChip({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitionRow(MentorCompetitionItem item) {
    final statusLabel = item.isPublished ? 'Publik' : 'Draft';
    final badgeColor = item.isPublished
        ? const Color(0xFFE3F5D9)
        : const Color(0xFFF3F0E7);
    final badgeTextColor = item.isPublished
        ? const Color(0xFF2E7D32)
        : const Color(0xFF7C6A2A);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF22C55E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isNotEmpty ? item.title : 'Try out',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.subject} · ${item.classLevel} · ${item.totalQuestions} soal',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.scheduleLabel.isNotEmpty
                      ? item.scheduleLabel
                      : item.durationLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOlimpiadeRow(MentorCompetitionItem item) {
    final statusLabel = item.isPublished ? 'Aktif' : 'Draft';
    final badgeColor = item.isPublished
        ? const Color(0xFFE6F6EF)
        : const Color(0xFFF3F0E7);
    final badgeTextColor = item.isPublished
        ? const Color(0xFF047857)
        : const Color(0xFF7C6A2A);
    final accentColor = item.subject.toLowerCase().contains('matematika')
        ? const Color(0xFF0F766E)
        : const Color(0xFFD97706);
    final icon = item.subject.toLowerCase().contains('matematika')
        ? Icons.calculate_outlined
        : Icons.science_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isNotEmpty ? item.title : 'Olimpiade Akademik',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.classLevel} · ${item.subject}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.scheduleLabel.isNotEmpty
                      ? item.scheduleLabel
                      : item.durationLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 84,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: item.isPublished ? 0.62 : 0.26,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarMenuItem {
  final String title;
  final IconData icon;
  const _SidebarMenuItem({required this.title, required this.icon});
}
