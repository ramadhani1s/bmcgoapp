import 'package:flutter/material.dart';
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

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> with RouteAware {
  User? _currentUser;
  String _activeMenuTitle = 'Dashboard';
  final TextEditingController _dashboardSearchController =
      TextEditingController();
  String _searchKeyword = '';
  bool _loadingDashboardCards = true;
  List<Map<String, dynamic>> _recentSchedules = [];
  List<MentorCompetitionItem> _recentTryouts = [];
  List<MentorCompetitionItem> _recentOlimpiades = [];

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
    _dashboardSearchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped and this route shows again.
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
    final schedules = await _safeLoad(
      JadwalService.getJadwalList(mentorId: mentorId),
      <Map<String, dynamic>>[],
    );
    final tryouts = await _safeLoad(
      MentorCompetitionService.getByType('tryout'),
      <MentorCompetitionItem>[],
    );
    final olimpiades = await _safeLoad(
      MentorCompetitionService.getByType('olimpiade'),
      <MentorCompetitionItem>[],
    );

    if (!mounted) return;
    setState(() {
      _recentSchedules = schedules.take(3).toList();
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

  String _formatScheduleTime(Map<String, dynamic> item) {
    final start = _pickValue(item, [
      'jam_mulai',
      'start_time',
      'jamAwal',
      'time_start',
    ]);
    final end = _pickValue(item, [
      'jam_selesai',
      'end_time',
      'jamAkhir',
      'time_end',
    ]);
    if (start == '-' && end == '-') {
      return _pickValue(item, ['jam', 'waktu'], fallback: 'Jadwal tersedia');
    }
    return '$start${end == '-' ? '' : ' - $end'}';
  }

  void _applySearch(String value) {
    setState(() {
      _searchKeyword = value.trim();
    });
  }

  void _clearSearch() {
    setState(() {
      _dashboardSearchController.clear();
      _searchKeyword = '';
    });
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
        MaterialPageRoute(builder: (_) => const JadwalPembelajaranScreen()),
      );
      await _loadStats();
      return;
    }
    if (title == 'Absensi Kelas') {
      await navigator.push(
        MaterialPageRoute(builder: (_) => const MentorAttendanceScreen()),
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
      await navigator.pushNamed(AppRoutes.mentorMateri);
      await _loadStats();
      return;
    }
    if (title == 'Olimpiade Akademik') {
      await navigator.push(
        MaterialPageRoute(builder: (_) => const MentorOlimpiadeScreen()),
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
        isMobile ? 16 : 18,
        isMobile ? 6 : 0,
        isMobile ? 16 : 18,
        20,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1340),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDashboardHeader(isMobile),
              const SizedBox(height: 10),
              _buildInlineSearchSection(),
              const SizedBox(height: 12),
              _buildHeroCard(),
              const SizedBox(height: 8),
              _buildTopPanels(),
              const SizedBox(height: 16),
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
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Color(0xFF1D4ED8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Selamat datang kembali, $displayName',
                    style: const TextStyle(
                      color: Color(0xFF0F766E),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
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

  Widget _buildInlineSearchSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110F172A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pencarian Dashboard',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Cari jadwal, try out, latihan, atau mapel langsung dari sini tanpa membuka panel lain.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dashboardSearchController,
                  onChanged: _applySearch,
                  onSubmitted: _applySearch,
                  decoration: InputDecoration(
                    hintText: 'Cari jadwal, try out, latihan, atau soal...',
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    suffixIcon: _searchKeyword.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close, size: 18),
                          ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF3B82F6),
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_searchKeyword.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Kata kunci: "$_searchKeyword"',
                    style: const TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';
    return InkWell(
      onTap: () {},
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
            const Text(
              'Profil',
              style: TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar({required bool forDrawer}) {
    final userName = (_currentUser?.nama ?? 'Mentor').trim();

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BMC Mentor',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                          height: 1.0,
                        ),
                      ),
                    ],
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
            onTap: _logout,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE4F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.space_dashboard_outlined,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang kembali di Dashboard Mentor',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Gunakan halaman ini untuk memantau kelas, mengelola soal, dan membuka materi dengan tampilan yang tetap rapi dan konsisten.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
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
    final keyword = _searchKeyword.toLowerCase();
    final filtered = keyword.isEmpty
        ? _recentSchedules
        : _recentSchedules.where((item) {
            final title = _pickValue(item, [
              'mata_pelajaran',
              'mapel',
              'subject',
              'judul',
              'nama',
            ]).toLowerCase();
            final kelas = _pickValue(item, [
              'kelas',
              'class_level',
              'class_name',
            ]).toLowerCase();
            final time = _formatScheduleTime(item).toLowerCase();
            return title.contains(keyword) ||
                kelas.contains(keyword) ||
                time.contains(keyword);
          }).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Jadwal Mengajar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const JadwalPembelajaranScreen(),
                    ),
                  );
                  await _loadDashboardCards();
                },
                child: const Text('Lihat semua'),
              ),
            ],
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
                      Icons.search_off_outlined,
                      size: 46,
                      color: Color(0xFFD1D5DB),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Tidak ada jadwal yang cocok dengan pencarian.',
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
    final keyword = _searchKeyword.toLowerCase();
    final filtered = keyword.isEmpty
        ? _recentTryouts
        : _recentTryouts
              .where(
                (t) => ('${t.title} ${t.subject} ${t.classLevel}')
                    .toLowerCase()
                    .contains(keyword),
              )
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
    );
  }

  Widget _buildOlimpiadeCard() {
    final keyword = _searchKeyword.toLowerCase();
    final filtered = keyword.isEmpty
        ? _recentOlimpiades
        : _recentOlimpiades.where((item) {
            final text =
                '${item.title} ${item.subject} ${item.classLevel} '
                        '${item.durationLabel} ${item.scheduleLabel} '
                        '${item.totalQuestions}'
                    .toLowerCase();
            return text.contains(keyword);
          }).toList();

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
    final kelas = _pickValue(item, [
      'kelas',
      'class_level',
      'class_name',
    ], fallback: 'Kelas');
    final ruang = _pickValue(item, ['ruang', 'room'], fallback: 'Ruang');
    final time = _formatScheduleTime(item);

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
                colors: [Color(0xFF1D4ED8), Color(0xFF10B981)],
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
                  '$title — $kelas',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: Color(0xFF111827),
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
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Jadwal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0369A1),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              TextButton(onPressed: onActionTap, child: Text(actionLabel)),
            ],
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
