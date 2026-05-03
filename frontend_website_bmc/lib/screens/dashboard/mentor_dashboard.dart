import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_observer.dart';
import '../../services/auth_service.dart';
import '../../services/mentor_competition_service.dart';
import '../../services/latihan_management_service.dart';
import '../../services/latihan_soal_service.dart';
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
  bool _showInlineSearch = false;
  String _searchKeyword = '';
  // dashboard stats
  int _totalLatihan = 0;
  int _publishedLatihan = 0;
  int _totalSoal = 0;
  int _mapelCount = 0;
  double _progressValue = 0;
  int _progressPercent = 0;
  bool _loadingStats = true;

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
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final latihanList = await LatihanManagementService.getLatihan();
      final soalList = await LatihanSoalService.getSoalLatihan();
      final tryoutList = await MentorCompetitionService.getByType('tryout');
      final olimpiadeList = await MentorCompetitionService.getByType(
        'olimpiade',
      );

      final mapels = <String>{};
      for (final l in latihanList) {
        if (l.mapel.trim().isNotEmpty) mapels.add(l.mapel.trim());
      }
      for (final soal in soalList) {
        final extracted = _extractMapelFromQuestion(soal.pertanyaan);
        if (extracted.isNotEmpty) mapels.add(extracted);
      }

      for (final item in [...tryoutList, ...olimpiadeList]) {
        if (item.subject.trim().isNotEmpty && item.subject.trim() != '-') {
          mapels.add(item.subject.trim());
        }
      }

      final totalLatihanOnly = latihanList.isNotEmpty
          ? latihanList.length
          : soalList.length;

      final publishedLatihanOnly = latihanList.isNotEmpty
          ? latihanList.where((l) => l.isPublished).length
          : soalList.length;

      final totalCompetitions = tryoutList.length + olimpiadeList.length;
      final publishedCompetitions =
          tryoutList.where((t) => t.isPublished).length +
          olimpiadeList.where((o) => o.isPublished).length;

      final totalContent = totalLatihanOnly + totalCompetitions;
      final publishedContent = publishedLatihanOnly + publishedCompetitions;

      final totalSoalFromLatihan = latihanList.fold<int>(
        0,
        (sum, l) => sum + l.totalSoal,
      );
      final totalSoalLatihan = totalSoalFromLatihan > soalList.length
          ? totalSoalFromLatihan
          : soalList.length;

      final totalSoalTryout = tryoutList.fold<int>(
        0,
        (sum, item) => sum + item.totalQuestions,
      );
      final totalSoalOlimpiade = olimpiadeList.fold<int>(
        0,
        (sum, item) => sum + item.totalQuestions,
      );
      final totalSoal = totalSoalLatihan + totalSoalTryout + totalSoalOlimpiade;

      final progressValue = totalContent == 0
          ? 0.0
          : (publishedContent / totalContent).clamp(0.0, 1.0);
      final progressPercent = (progressValue * 100).round();

      if (mounted) {
        setState(() {
          _totalLatihan = totalContent;
          _publishedLatihan = publishedContent;
          _totalSoal = totalSoal;
          _mapelCount = mapels.length;
          _progressValue = progressValue;
          _progressPercent = progressPercent;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  String _extractMapelFromQuestion(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('[')) return '';
    final closeIdx = trimmed.indexOf(']');
    if (closeIdx <= 1) return '';
    return trimmed.substring(1, closeIdx).trim();
  }

  void _toggleInlineSearch() {
    setState(() {
      _showInlineSearch = !_showInlineSearch;
      if (!_showInlineSearch) {
        _dashboardSearchController.clear();
        _searchKeyword = '';
      }
    });
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

  void _showProfileDialog() {
    final user = _currentUser;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Profil'),
        content: user == null
            ? const Text('Tidak ada data pengguna')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nama: ${user.nama}'),
                  const SizedBox(height: 6),
                  Text('Email: ${user.email}'),
                  const SizedBox(height: 6),
                  Text('Peran: ${user.roleName}'),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) setState(() => _currentUser = user);
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
    if (title == 'Jadwal Mengajar') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JadwalPembelajaranScreen()),
      );
      await _loadStats();
      return;
    }
    if (title == 'Absensi Kelas') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const MentorAttendanceScreen()));
      await _loadStats();
      return;
    }
    if (title == 'Soal Latihan') {
      await Navigator.of(context).pushNamed(AppRoutes.mentorExercise);
      await _loadStats();
    }
    if (title == 'Try Out') {
      await Navigator.of(context).pushNamed(AppRoutes.mentorTryout);
      await _loadStats();
    }
    if (title == 'Materi Pembelajaran') {
      await Navigator.of(context).pushNamed(AppRoutes.mentorMateri);
      await _loadStats();
    }
    if (title == 'Olimpiade Akademik') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const MentorOlimpiadeScreen()));
      await _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
              if (_showInlineSearch) ...[
                const SizedBox(height: 10),
                _buildInlineSearchSection(),
              ],
              const SizedBox(height: 12),
              _buildHeroCard(),
              const SizedBox(height: 18),
              _buildStatsGrid(),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 920;
                  final leftPanel = _buildQuickActionsCard();
                  final rightPanel = _buildProgressCard();

                  if (stacked) {
                    return Column(
                      children: [
                        leftPanel,
                        const SizedBox(height: 16),
                        rightPanel,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: leftPanel),
                      const SizedBox(width: 16),
                      Expanded(child: rightPanel),
                    ],
                  );
                },
              ),
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
        _buildTopActionButton(
          Icons.search_outlined,
          onTap: _toggleInlineSearch,
        ),
        const SizedBox(width: 10),
        _buildNotificationButton(),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showProfileDialog,
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dashboardSearchController,
                  onChanged: _applySearch,
                  onSubmitted: _applySearch,
                  decoration: InputDecoration(
                    hintText: 'Cari latihan, mapel, atau soal...',
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
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _toggleInlineSearch,
                icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                label: const Text('Tutup'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
              ),
            ],
          ),
          if (_searchKeyword.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

  Widget _buildStatsGrid() {
    final stats = [
      _DashboardStatData(
        'Total Konten',
        _loadingStats ? '—' : '$_totalLatihan',
        Icons.assignment,
        Colors.blue,
      ),
      _DashboardStatData(
        'Dipublikasikan',
        _loadingStats ? '—' : '$_publishedLatihan',
        Icons.check_circle,
        Colors.green,
      ),
      _DashboardStatData(
        'Total Soal',
        _loadingStats ? '—' : '$_totalSoal',
        Icons.help,
        Colors.orange,
      ),
      _DashboardStatData(
        'Mapel',
        _loadingStats ? '—' : '$_mapelCount',
        Icons.category,
        Colors.purple,
      ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stats
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _statCard(s),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _statCard(_DashboardStatData s) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: s.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(s.icon, color: s.color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            s.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: s.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tindakan Cepat',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.mentorExercise);
                  await _loadStats();
                },
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Buat Latihan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF1D4ED8),
                  elevation: 0,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.mentorMateri),
                icon: const Icon(Icons.video_library_outlined),
                label: const Text('Upload Materi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0FDF4),
                  foregroundColor: const Color(0xFF166534),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _loadingStats ? 0 : _progressValue,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loadingStats
                ? 'Memuat progress...'
                : '$_progressPercent% konten sudah dipublikasikan',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
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

class _DashboardStatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _DashboardStatData(this.label, this.value, this.icon, this.color);
}
