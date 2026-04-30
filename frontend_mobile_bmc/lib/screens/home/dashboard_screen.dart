import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/services/payment_service.dart';
import 'package:frontend_mobile_bmc/services/jadwal_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color _accent = Color(0xFFFF7070);
  static const Color _background = Color(0xFFF7EEEF);
  static const Color _textPrimary = Color(0xFF25273D);
  static const Color _textMuted = Color(0xFF8D90A3);

  int _selectedIndex = 0;
  int _previousIndex = 0;
  bool _canAccessPaidFeatures = false;
  bool _hasAutoNavigatedToProfile = false;
  bool _isCheckingVerification = true;
  String _activePackageTitle = 'Paket belum dipilih';
  bool _isLoadingPackageInfo = true;
  int _openedMateriCount = 0;
  int _openedTryoutCount = 0;

  // Jadwal variables
  List<Map<String, dynamic>> _jadwalList = [];
  bool _isLoadingJadwal = true;

  int get _totalMateriTarget => 24;
  int get _totalTryoutTarget => 12;

  double get _overallProgress {
    final total = _totalMateriTarget + _totalTryoutTarget;
    if (total <= 0) {
      return 0;
    }
    final opened = _openedMateriCount + _openedTryoutCount;
    return (opened / total).clamp(0, 1);
  }

  int get _overallProgressPercent => (_overallProgress * 100).round();

  @override
  void initState() {
    super.initState();
    _loadLearningProgress();
    _loadDashboardStatus();
    _loadJadwalHariIni();
  }

  String _progressKey(String suffix) {
    return 'learning_progress_${_studentEmail}_$suffix';
  }

  Future<void> _loadLearningProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    setState(() {
      _openedMateriCount = prefs.getInt(_progressKey('materi_opened')) ?? 0;
      _openedTryoutCount = prefs.getInt(_progressKey('tryout_opened')) ?? 0;
    });
  }

  Future<void> _saveLearningProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_progressKey('materi_opened'), _openedMateriCount);
    await prefs.setInt(_progressKey('tryout_opened'), _openedTryoutCount);
  }

  Future<void> _incrementMateriProgress() async {
    if (!_isActive || _openedMateriCount >= _totalMateriTarget) {
      return;
    }

    setState(() {
      _openedMateriCount += 1;
    });
    await _saveLearningProgress();
  }

  Future<void> _incrementTryoutProgress() async {
    if (!_isActive || _openedTryoutCount >= _totalTryoutTarget) {
      return;
    }

    setState(() {
      _openedTryoutCount += 1;
    });
    await _saveLearningProgress();
  }

  Future<void> _loadDashboardStatus() async {
    final canAccess = await PaymentService.getVerificationStatus();

    String packageTitle = 'Paket belum dipilih';
    try {
      final history = await PaymentService.getPaymentHistory();
      if (history.isNotEmpty) {
        final successItems = history
            .where((item) => item.status.toLowerCase() == 'success')
            .toList();
        final selectedItem = successItems.isNotEmpty
            ? successItems.first
            : history.first;
        packageTitle = selectedItem.packageTitle;
      }
    } catch (_) {
      // Keep fallback when history cannot be loaded.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      if (canAccess && !_hasAutoNavigatedToProfile) {
        _previousIndex = _selectedIndex;
        _selectedIndex = 3;
        _hasAutoNavigatedToProfile = true;
      }
      _canAccessPaidFeatures = canAccess;
      _isCheckingVerification = false;
      _activePackageTitle = packageTitle;
      _isLoadingPackageInfo = false;
    });
  }

  bool get _isActive => _canAccessPaidFeatures;

  String get _studentName {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final user = args?['user'] as Map<String, dynamic>?;
    return (user?['nama'] as String?) ?? 'Yohana Nababan';
  }

  String get _classLabel {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final user = args?['user'] as Map<String, dynamic>?;
    return (user?['kelas'] as String?) ?? 'Kelas 12';
  }

  String get _studentEmail {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final user = args?['user'] as Map<String, dynamic>?;
    return (user?['email'] as String?) ?? '-';
  }

  Future<void> _loadJadwalHariIni() async {
    try {
      // Get current day name in Indonesian
      final now = DateTime.now();
      const hariList = [
        'Minggu',
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
      ];
      final hariIni = hariList[now.weekday % 7];

      final jadwalData = await JadwalMobileService.getJadwalByHari(hariIni);

      if (!mounted) return;

      setState(() {
        _jadwalList = jadwalData;
        _isLoadingJadwal = false;
      });
    } catch (e) {
      print("❌ Error loading jadwal: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingJadwal = false;
      });
    }
  }

  String get _firstName {
    final parts = _studentName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return _studentName;
    }
    return parts.first;
  }

  List<_MainMenuItem> get _menuItems => const [
    _MainMenuItem(
      'Materi',
      Icons.menu_book_rounded,
      Color(0xFFFFF0F0),
      iconColor: Color(0xFFFF6F72),
    ),
    _MainMenuItem(
      'Try Out',
      Icons.description_outlined,
      Color(0xFFEDEBFF),
      iconColor: Color(0xFF6C67FF),
    ),
    _MainMenuItem(
      'Olimpiade',
      Icons.emoji_events_outlined,
      Color(0xFFFFF6D9),
      iconColor: Color(0xFFF0C31D),
    ),
    _MainMenuItem(
      'Absensi',
      Icons.fact_check_outlined,
      Color(0xFFE3FBF4),
      iconColor: Color(0xFF12B892),
    ),
    _MainMenuItem(
      'Pembayaran',
      Icons.credit_card_rounded,
      Color(0xFFDCEBFF),
      iconColor: Color(0xFF4B9BFF),
    ),
    _MainMenuItem(
      'Pengumuman',
      Icons.campaign_outlined,
      Color(0xFFFFF0F4),
      iconColor: Color(0xFFFF6A88),
    ),
    _MainMenuItem(
      'Alumni',
      Icons.school_outlined,
      Color(0xFFEDE7FF),
      iconColor: Color(0xFF6D3CEB),
    ),
  ];

  List<_AlumniPreviewItem> get _alumniPreview => const [
    _AlumniPreviewItem(
      initials: 'A',
      name: 'Ahmad F.',
      facultyLine: 'ITB 2024',
      majorLine: 'Teknik Informatika',
      avatarColor: Color(0xFF6D67F6),
    ),
    _AlumniPreviewItem(
      initials: 'S',
      name: 'Siti R.',
      facultyLine: 'UI 2023',
      majorLine: 'Kedokteran',
      avatarColor: Color(0xFFFF6D70),
    ),
    _AlumniPreviewItem(
      initials: 'D',
      name: 'Dimas P.',
      facultyLine: 'UGM 2024',
      majorLine: 'Hukum',
      avatarColor: Color(0xFFF7A13A),
    ),
  ];

  List<_SchedulePreviewItem> get _schedulePreview {
    // Convert dynamic jadwal data to SchedulePreviewItem
    if (_jadwalList.isEmpty) {
      return const [];
    }

    return _jadwalList.map((jadwal) {
      final waktuMulai = jadwal['waktu_mulai'] as String? ?? '00:00';
      final mataPelajaran =
          jadwal['mata_pelajaran'] as String? ?? 'Pembelajaran';
      final mentor = jadwal['mentor'] as String? ?? 'Mentor';
      final ruang = jadwal['ruang'] as String? ?? 'Ruang';

      // Determine status based on current time
      String status = 'Akan Datang';
      Color statusColor = const Color(0xFF5194F8);
      Color statusBackground = const Color(0xFFE9F2FF);

      final now = DateTime.now();
      final scheduledTime = _parseTime(waktuMulai);
      final timeDiff = scheduledTime.difference(now).inMinutes;

      if (timeDiff < -30) {
        status = 'Selesai';
        statusColor = const Color(0xFF8D90A3);
        statusBackground = const Color(0xFFF0F2F7);
      } else if (timeDiff <= 0) {
        status = 'Sekarang';
        statusColor = const Color(0xFF1CC08A);
        statusBackground = const Color(0xFFDEF8EF);
      } else if (timeDiff <= 30) {
        status = 'Segera';
        statusColor = const Color(0xFFF39A44);
        statusBackground = const Color(0xFFFFF0E0);
      }

      return _SchedulePreviewItem(
        time: waktuMulai,
        subject: mataPelajaran,
        mentorRoom: '$mentor · $ruang',
        status: status,
        statusColor: statusColor,
        statusBackground: statusBackground,
      );
    }).toList();
  }

  DateTime _parseTime(String timeStr) {
    // Parse time string like "08:00" to DateTime
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      return DateTime.now();
    }
  }

  void _onBottomNavTap(int index) {
    if (!_isActive && (index == 1 || index == 2)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Akun kamu masih non-aktif. Aktivasi dulu di menu Profil.',
          ),
          backgroundColor: _accent,
        ),
      );
      return;
    }

    if (index == 1) {
      _incrementMateriProgress();
    }
    if (index == 2) {
      _incrementTryoutProgress();
      Navigator.of(context).pushNamed('/mentor-tryout');
      return;
    }

    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  void _onMainMenuTap(String menuKey) {
    if (menuKey.toLowerCase() == 'try out') {
      _incrementTryoutProgress();
      Navigator.of(context).pushNamed('/mentor-tryout');
      return;
    }

    if (menuKey.toLowerCase() == 'olimpiade') {
      Navigator.of(context).pushNamed('/mentor-olimpiade');
      return;
    }

    if (menuKey.toLowerCase() == 'absensi') {
      Navigator.of(context).pushNamed('/attendance');
      return;
    }

    if (!_isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fitur belum bisa diakses. Aktivasi akun dulu di halaman Profil.',
          ),
          backgroundColor: _accent,
        ),
      );
      return;
    }

    if (menuKey.toLowerCase() == 'materi') {
      _incrementMateriProgress();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Menu $menuKey siap dihubungkan ke data dinamis.'),
          backgroundColor: const Color(0xFF23A66F),
        ),
      );
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                decoration: const BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(38),
                    bottomRight: Radius.circular(38),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              'assets/images/bmc_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BMC',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 29,
                                  height: 1,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Bintang Muda Center',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.95 * 255).round()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  color: _accent,
                                ),
                              ),
                              Positioned(
                                right: 9,
                                top: 10,
                                child: CircleAvatar(
                                  radius: 7,
                                  backgroundColor: Color(0xFFFDCF52),
                                  child: Text(
                                    '1',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Selamat datang kembali.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_studentName ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F8),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFFF8F53),
                                child: Text(
                                  _firstName.characters.first.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _studentName,
                                      style: const TextStyle(
                                        color: _textPrimary,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _isLoadingPackageInfo
                                          ? '$_classLabel · Memuat paket...'
                                          : '$_classLabel · $_activePackageTitle',
                                      style: const TextStyle(
                                        color: _textMuted,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _isActive
                                      ? const Color(0xFFFFF4E2)
                                      : const Color(0xFFFFEFEF),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _isActive
                                        ? const Color(0xFFF7D4A4)
                                        : const Color(0xFFFFCFD1),
                                  ),
                                ),
                                child: Text(
                                  _isCheckingVerification
                                      ? 'Mengecek...'
                                      : (_isActive ? '• Aktif' : '• Non-Aktif'),
                                  style: TextStyle(
                                    color: _isActive
                                        ? const Color(0xFFB2771E)
                                        : const Color(0xFFD45767),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text(
                                'Progress Belajar',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$_overallProgressPercent%',
                                style: const TextStyle(
                                  color: Color(0xFFFF6A6E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: _overallProgress,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE7E8EC),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF7E63),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _TopMetricCard(
                                  value: '$_openedMateriCount',
                                  label: 'Materi',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _TopMetricCard(
                                  value:
                                      '${_openedMateriCount + _openedTryoutCount}',
                                  label: 'Latihan',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _TopMetricCard(
                                  value: '$_openedTryoutCount',
                                  label: 'Try Out',
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
              Positioned(
                top: 16,
                right: -32,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.12 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 98,
                right: 80,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.09 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3CED0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFA19AA2),
                      ),
                      hintText: 'Cari materi, soal, jadwal, alumni...',
                      hintStyle: const TextStyle(
                        color: Color(0xFFA19AA2),
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Menu Utama',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _menuItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.74,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    return GestureDetector(
                      onTap: () => _onMainMenuTap(item.label),
                      child: Opacity(
                        opacity: _isActive ? 1 : 0.82,
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    color: item.backgroundColor,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: item.iconColor,
                                    size: 27,
                                  ),
                                ),
                                if (!_isActive)
                                  const Positioned(
                                    right: -2,
                                    top: -2,
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.lock_rounded,
                                        size: 12,
                                        color: Color(0xFFA1A2AE),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: _textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFFF856E),
                        child: Icon(
                          Icons.campaign_outlined,
                          color: Color(0xFFFFD35E),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengumuman Baru!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Try Out SNBT: Sabtu, 15 Maret 2025',
                              style: TextStyle(
                                color: Color(0xFFFFE5E5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _SectionTitleRow(
                  title: 'Alumni Berprestasi',
                  actionText: 'Lihat Semua',
                  onTap: _showDynamicInfo,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _alumniPreview.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = _alumniPreview[index];
                      return _AlumniPreviewCard(item: item);
                    },
                  ),
                ),
                const SizedBox(height: 22),
                _SectionTitleRow(
                  title: 'Materi Terbaru',
                  actionText: 'Lihat Semua',
                  onTap: _showDynamicInfo,
                ),
                const SizedBox(height: 12),
                const _EmptyDataCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Materi belum tersedia',
                  description:
                      'Materi terbaru akan tampil di sini setelah mentor mengunggah konten.',
                ),
                const SizedBox(height: 22),
                const _SectionTitleRow(
                  title: 'Jadwal Hari Ini',
                  trailingText: 'Sen, 10 Feb',
                  trailingIcon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 12),
                for (final item in _schedulePreview) ...[
                  _SchedulePreviewTile(item: item),
                  const SizedBox(height: 10),
                ],
                if (!_isActive) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD0D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: _accent,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Akun kamu masih non-aktif',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Lengkapi profil dan pilih paket agar akses belajar bisa dibuka.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _textMuted,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _previousIndex = _selectedIndex;
                                _selectedIndex = 3;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.person_outline,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Buka Profil',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab({required String title, required IconData icon}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8E8),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: _accent, size: 40),
            ),
            const SizedBox(height: 14),
            Text(
              '$title masih menunggu data dinamis',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Data akan muncul setelah admin dan mentor melakukan input konten.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMuted, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final isActive = _isActive;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            decoration: const BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = _previousIndex == 3 ? 0 : _previousIndex;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.22 * 255).round()),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Profil',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF90A1C3),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(77, 91, 132, 0.22),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Center(
                              child: Icon(
                                Icons.school_rounded,
                                size: 46,
                                color: Color(0xFF586A94),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F0),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _accent,
                                    width: 1.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.photo_camera_outlined,
                                  size: 14,
                                  color: _accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _studentName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _studentEmail,
                        style: const TextStyle(
                          color: Color(0xFFDCE1ED),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStat('0', 'Materi'),
                          _buildDivider(),
                          _buildStat('0', 'Try Out'),
                          _buildDivider(),
                          _buildStat('0', 'Absensi'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F0),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: _accent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isLoadingPackageInfo
                                        ? 'Memuat informasi paket...'
                                        : _activePackageTitle,
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isActive
                                        ? 'Paket aktif. Semua fitur belajar bisa digunakan.'
                                        : 'Masuk ke Informasi Paket untuk memilih paket',
                                    style: const TextStyle(
                                      color: _textMuted,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFFC2C2C2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Detail Akun',
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSectionTitle('AKUN'),
                _buildTileCard(
                  children: [
                    _ProfileTile(
                      icon: Icons.person_outline,
                      title: 'Detail Profil',
                      color: const Color(0xFFEAF4FF),
                      onTap: () {
                        final args =
                            ModalRoute.of(context)?.settings.arguments
                                as Map<String, dynamic>? ??
                            const <String, dynamic>{};
                        final user =
                            args['user'] as Map<String, dynamic>? ??
                            const <String, dynamic>{};
                        Navigator.of(context).pushNamed(
                          '/profile-detail',
                          arguments: {'user': user},
                        );
                      },
                    ),
                    _ProfileTile(
                      icon: Icons.badge_outlined,
                      title: 'Informasi Paket',
                      color: const Color(0xFFF2E9FF),
                      onTap: () {
                        Navigator.of(context).pushNamed('/package');
                      },
                    ),
                    _ProfileTile(
                      icon: Icons.shield_outlined,
                      title: isActive
                          ? 'Status Akun: Aktif'
                          : 'Status Akun: Non-Aktif',
                      color: const Color(0xFFFFF1E7),
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildSectionTitle('AKADEMIK'),
                _buildTileCard(
                  children: [
                    _ProfileTile(
                      icon: Icons.military_tech_outlined,
                      title: 'Prestasi & Sertifikat',
                      color: const Color(0xFFFFF7DD),
                      onTap: _showDynamicInfo,
                    ),
                    _ProfileTile(
                      icon: Icons.fact_check_outlined,
                      title: 'Riwayat Kehadiran',
                      color: const Color(0xFFEAF8ED),
                      onTap: _showDynamicInfo,
                    ),
                    _ProfileTile(
                      icon: Icons.menu_book_outlined,
                      title: 'Transkrip Nilai',
                      color: const Color(0xFFE7F8FD),
                      onTap: _showDynamicInfo,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _accent),
                      foregroundColor: _accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Keluar dari Akun',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String title) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Color(0xFFDCE1ED), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 46, color: const Color(0xFFA6B2CC));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF9A9AA8),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTileCard({required List<_ProfileTile> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: children[i].color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(children[i].icon, color: const Color(0xFF3E4B6E)),
              ),
              title: Text(
                children[i].title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFC7C7C7),
              ),
              onTap: children[i].onTap,
            ),
            if (i != children.length - 1)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F1F1)),
          ],
        ],
      ),
    );
  }

  void _showDynamicInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Bagian ini akan aktif setelah data akademik tersedia dari admin/mentor.',
        ),
        backgroundColor: _accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _buildDashboardTab(),
      _buildPlaceholderTab(title: 'Materi', icon: Icons.menu_book_rounded),
      _buildPlaceholderTab(title: 'Try Out', icon: Icons.description_outlined),
      _buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: tabs),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _accent,
        unselectedItemColor: const Color(0xFF8F91A0),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11.5,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Materi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Try Out',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _MainMenuItem {
  const _MainMenuItem(
    this.label,
    this.icon,
    this.backgroundColor, {
    this.iconColor = const Color(0xFFFF7070),
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
}

class _TopMetricCard extends StatelessWidget {
  const _TopMetricCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEAEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFF6368),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E90A0),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({
    required this.title,
    this.actionText,
    this.onTap,
    this.trailingText,
    this.trailingIcon,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onTap;
  final String? trailingText;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF22243A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (actionText != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText!,
              style: const TextStyle(
                color: Color(0xFFFF666C),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (trailingText != null) ...[
          if (trailingIcon != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                trailingIcon,
                size: 14,
                color: const Color(0xFFABB0BE),
              ),
            ),
          Text(
            trailingText!,
            style: const TextStyle(color: Color(0xFFABB0BE), fontSize: 15),
          ),
        ],
      ],
    );
  }
}

class _AlumniPreviewItem {
  const _AlumniPreviewItem({
    required this.initials,
    required this.name,
    required this.facultyLine,
    required this.majorLine,
    required this.avatarColor,
  });

  final String initials;
  final String name;
  final String facultyLine;
  final String majorLine;
  final Color avatarColor;
}

class _AlumniPreviewCard extends StatelessWidget {
  const _AlumniPreviewCard({required this.item});

  final _AlumniPreviewItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: item.avatarColor,
            child: Text(
              item.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF22243A),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.facultyLine,
            style: const TextStyle(
              color: Color(0xFFFF6E72),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.majorLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFA2A7B5), fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _EmptyDataCard extends StatelessWidget {
  const _EmptyDataCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFCECED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFFF7070)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF25273D),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF8D90A3),
                    fontSize: 12.5,
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
}

class _SchedulePreviewItem {
  const _SchedulePreviewItem({
    required this.time,
    required this.subject,
    required this.mentorRoom,
    required this.status,
    required this.statusColor,
    required this.statusBackground,
  });

  final String time;
  final String subject;
  final String mentorRoom;
  final String status;
  final Color statusColor;
  final Color statusBackground;
}

class _SchedulePreviewTile extends StatelessWidget {
  const _SchedulePreviewTile({required this.item});

  final _SchedulePreviewItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.time,
                  style: const TextStyle(
                    color: Color(0xFFFF656B),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'WIB',
                  style: TextStyle(color: Color(0xFFB2B7C5), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 34, color: const Color(0xFFECEEF4)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subject,
                  style: const TextStyle(
                    color: Color(0xFF22243A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.mentorRoom,
                  style: const TextStyle(
                    color: Color(0xFF9297A6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: item.statusBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.status,
              style: TextStyle(
                color: item.statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
}
