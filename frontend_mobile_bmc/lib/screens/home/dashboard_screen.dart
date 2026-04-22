import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Palet warna utama untuk seluruh halaman dashboard siswa.
  static const Color _accent = Color(0xFFFF7070);
  static const Color _background = Color(0xFFF7EEEF);
  static const Color _textPrimary = Color(0xFF25273D);
  static const Color _textMuted = Color(0xFF8D90A3);

  // State navigasi bawah: index aktif saat ini dan index sebelumnya.
  int _selectedIndex = 0;
  int _previousIndex = 0;
  int _lastMainTabIndex = 0;

  // Ambil status aktivasi akun dari argument route login.
  bool get _isActive {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final user = args?['user'] as Map<String, dynamic>?;
    return user?['is_active'] == true;
  }

  // Ambil nama siswa dari argument route, fallback untuk mode demo.
  String get _studentName {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final user = args?['user'] as Map<String, dynamic>?;
    return (user?['nama'] as String?) ?? 'Yohana Nababan';
  }

  // Ambil label kelas siswa dari argument route.
  String get _classLabel {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final user = args?['user'] as Map<String, dynamic>?;
    return (user?['kelas'] as String?) ?? 'Kelas 12';
  }

  // Batasi akses tab Materi dan Try Out bila akun siswa belum aktif.
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

    setState(() {
      if (index != 3) {
        _lastMainTabIndex = index;
      }
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

<<<<<<< Updated upstream
  // Handler menu utama pada beranda (sementara masih placeholder).
=======
  void _goBackFromProfile() {
    final targetTab = _previousIndex != 3 ? _previousIndex : _lastMainTabIndex;
    setState(() {
      _selectedIndex = targetTab.clamp(0, 2);
    });
  }

>>>>>>> Stashed changes
  void _onMainMenuTap(String menuKey) {
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menu $menuKey siap dihubungkan ke data dinamis.'),
        backgroundColor: const Color(0xFF23A66F),
      ),
    );
  }

  // Tab Beranda siswa: header profil singkat, menu utama, dan status akun.
  Widget _buildDashboardTab() {
    final menuItems = <_MainMenuItem>[
      const _MainMenuItem('Materi', Icons.menu_book_rounded, Color(0xFFFDECEC)),
      const _MainMenuItem(
        'Try Out',
        Icons.description_outlined,
        Color(0xFFEAEAFE),
      ),
      const _MainMenuItem(
        'Olimpiade',
        Icons.emoji_events_outlined,
        Color(0xFFFFF5DA),
      ),
      const _MainMenuItem(
        'Absensi',
        Icons.fact_check_outlined,
        Color(0xFFE6FBF3),
      ),
      const _MainMenuItem(
        'Jenis Paket',
        Icons.credit_card_outlined,
        Color(0xFFE8F2FF),
      ),
      const _MainMenuItem(
        'Pengumuman',
        Icons.campaign_outlined,
        Color(0xFFFFEDF1),
      ),
      const _MainMenuItem('Alumni', Icons.school_outlined, Color(0xFFEDE8FF)),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header atas berisi branding BMC, salam, dan ringkasan siswa.
          Container(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            decoration: const BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(34),
                bottomRight: Radius.circular(34),
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
                          'assets/images/bmc_logo.jpeg',
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
                              fontSize: 30,
                            ),
                          ),
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
                        color: Colors.white.withOpacity(0.95),
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
                            right: 10,
                            top: 11,
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: Color(0xFFFF3F3F),
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
                  _studentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFFF8F53),
                        child: Text(
                          _studentName.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
                              '$_classLabel · Paket belum dipilih',
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: const [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(99),
                                    ),
                                    child: LinearProgressIndicator(
                                      value: 0,
                                      minHeight: 6,
                                      backgroundColor: Color(0xFFE9EAF0),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFFB082),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '0%',
                                  style: TextStyle(
                                    color: Color(0xFFFF8D3C),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2E8),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFFFCF9F)),
                        ),
                        child: const Text(
                          'Non-Aktif',
                          style: TextStyle(
                            color: Color(0xFFFF8D3C),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Expanded(
                      child: _TopMetricCard(value: '0', label: 'Materi'),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _TopMetricCard(value: '0', label: 'Latihan'),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _TopMetricCard(value: '0', label: 'Try Out'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Area konten berisi pencarian, grid menu, dan info aktivasi akun.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar nonaktif sebagai placeholder pencarian global.
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8CCCF),
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
                // Menu utama siswa dalam bentuk grid 4 kolom.
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: menuItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.74,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
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
                                    color: _accent,
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
                // Kartu edukasi jika akun masih non-aktif.
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
                        'Untuk membuka akses Materi, Try Out, dan fitur lain, silakan pilih paket bimbel dari menu Profil.',
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
                            'Buka Profil & Pilih Paket',
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
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder tab untuk fitur yang menunggu data dinamis dari backend.
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

  // Tab Profil siswa: identitas, statistik, detail akun, dan aksi logout.
  Widget _buildProfileTab() {
    final isActive = _isActive;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header profil dengan tombol kembali ke tab sebelumnya.
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
                  onTap: _goBackFromProfile,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
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
          // Konten profil: kartu utama, detail akun, akademik, dan logout.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kartu identitas siswa dan status paket belajar.
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
                      const Text(
                        'yohana.nababan@bmc.id',
                        style: TextStyle(
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
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Belum ada paket dipilih',
                                    style: TextStyle(
                                      color: _textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Masuk ke Informasi Paket untuk memilih paket',
                                    style: TextStyle(
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
                // Grup menu akun (profil, paket, status aktivasi).
                _buildSectionTitle('AKUN'),
                _buildTileCard(
                  children: [
                    _ProfileTile(
                      icon: Icons.person_outline,
                      title: 'Detail Profil',
                      color: const Color(0xFFEAF4FF),
                      onTap: () {},
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
                // Grup menu akademik siswa (placeholder data nilai/prestasi).
                _buildSectionTitle('AKADEMIK'),
                _buildTileCard(
                  children: [
                    _ProfileTile(
                      icon: Icons.military_tech_outlined,
                      title: 'Prestasi & Sertifikat',
                      color: const Color(0xFFFFF7DD),
                      onTap: () {
                        _showDynamicInfo();
                      },
                    ),
                    _ProfileTile(
                      icon: Icons.fact_check_outlined,
                      title: 'Riwayat Kehadiran',
                      color: const Color(0xFFEAF8ED),
                      onTap: () {
                        _showDynamicInfo();
                      },
                    ),
                    _ProfileTile(
                      icon: Icons.menu_book_outlined,
                      title: 'Transkrip Nilai',
                      color: const Color(0xFFE7F8FD),
                      onTap: () {
                        _showDynamicInfo();
                      },
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

  // Komponen statistik ringkas pada kartu profil.
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

  // Garis pemisah antar statistik pada kartu profil.
  Widget _buildDivider() {
    return Container(width: 1, height: 46, color: const Color(0xFFA6B2CC));
  }

  // Judul section untuk pengelompokan menu di tab profil.
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

  // Kartu daftar tile reusable untuk menu profil.
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

  // Notifikasi sementara untuk fitur yang belum terhubung data akademik.
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
    // Susunan tab utama yang dipilih lewat BottomNavigationBar.
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
      // Navigasi utama siswa: Beranda, Materi, Try Out, dan Profil.
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

// Model sederhana untuk item menu utama di beranda.
class _MainMenuItem {
  const _MainMenuItem(this.label, this.icon, this.backgroundColor);

  final String label;
  final IconData icon;
  final Color backgroundColor;
}

// Kartu metrik kecil yang tampil di bagian atas dashboard.
class _TopMetricCard extends StatelessWidget {
  const _TopMetricCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEF0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFF7070),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E90A0),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Model data untuk tile pada daftar menu tab profil.
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
