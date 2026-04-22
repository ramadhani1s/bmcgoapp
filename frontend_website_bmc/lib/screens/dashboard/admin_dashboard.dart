import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  User? _currentUser;
  int _selectedMenuIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _onMenuTap(int index, _SideMenuItem item) {
    setState(() {
      _selectedMenuIndex = index;
    });

    if (item.route != null) {
      Navigator.of(context).pushNamed(item.route!);
    }
  }

  List<_SideMenuItem> get _menuItems => const [
    _SideMenuItem('Dashboard', Icons.grid_view_rounded),
    _SideMenuItem(
      'Verifikasi Pendaftaran',
      Icons.fact_check_outlined,
      route: '/payment-verification',
    ),
    _SideMenuItem('Kelola Mentor', Icons.groups_2_outlined),
    _SideMenuItem('Kelola Jadwal', Icons.event_note_outlined),
    _SideMenuItem('Kelola Absensi', Icons.assignment_turned_in_outlined),
    _SideMenuItem('Kelola Pengumuman', Icons.campaign_outlined),
    _SideMenuItem('Kelola Paket Les', Icons.school_outlined),
    _SideMenuItem('Kelola Profil Alumni', Icons.badge_outlined),
  ];

  List<_StatCardData> get _stats => const [
    _StatCardData(
      title: 'Menunggu Verifikasi',
      value: '2',
      subtitle: 'Pendaftaran Siswa Baru',
      color: Color(0xFFFF7A00),
      backgroundColor: Color(0xFFF6EFE7),
      icon: Icons.person_add_alt_1,
    ),
    _StatCardData(
      title: 'Jadwal Hari Ini',
      value: '4',
      subtitle: 'Kelas Aktif',
      color: Color(0xFF2E7BEF),
      backgroundColor: Color(0xFFF0F5FF),
      icon: Icons.calendar_month,
    ),
    _StatCardData(
      title: 'Siswa Aktif',
      value: '45',
      subtitle: 'Total Siswa Terdaftar',
      color: Color(0xFF17BF63),
      backgroundColor: Color(0xFFEDF8F0),
      icon: Icons.groups,
    ),
  ];

  List<_PendingVerificationRow> get _pendingRows => const [
    _PendingVerificationRow(
      name: 'Putri Rahayu',
      school: 'SMAN 1 Bandung',
      className: 'Kelas 10',
      date: '13 Mar 2025',
      status: 'Menunggu',
    ),
    _PendingVerificationRow(
      name: 'Dimas Pratama',
      school: 'SMAN 1 Bandung',
      className: 'Kelas 12',
      date: '13 Mar 2025',
      status: 'Disetujui',
    ),
    _PendingVerificationRow(
      name: 'Rina Sari',
      school: 'SMAN 2 Bandung',
      className: 'Kelas 11',
      date: '12 Mar 2025',
      status: 'Ditolak',
    ),
  ];

  List<_ScheduleRow> get _scheduleRows => const [
    _ScheduleRow(
      time: '08:00 - 10:00',
      className: 'Kelas 10',
      subject: 'Matematika',
      mentor: 'Bu Sarah',
      room: 'Ruang A',
      status: 'Berlangsung',
    ),
    _ScheduleRow(
      time: '10:00 - 12:00',
      className: 'Kelas 11',
      subject: 'Fisika',
      mentor: 'Pak Andi',
      room: 'Ruang B',
      status: 'Akan Datang',
    ),
    _ScheduleRow(
      time: '13:00 - 15:00',
      className: 'Kelas 12',
      subject: 'Kimia',
      mentor: 'Bu Rini',
      room: 'Ruang C',
      status: 'Akan Datang',
    ),
    _ScheduleRow(
      time: '15:30 - 17:00',
      className: 'Kelas 10',
      subject: 'Biologi',
      mentor: 'Pak Dodi',
      room: 'Ruang A',
      status: 'Akan Datang',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F8),
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 14),
                        _buildHeroCard(),
                        const SizedBox(height: 14),
                        _buildStatsRow(),
                        const SizedBox(height: 14),
                        _buildPendingVerificationCard(),
                        const SizedBox(height: 12),
                        _buildScheduleCard(),
                      ],
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

  Widget _buildSidebar() {
    return Container(
      width: 214,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF6),
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
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
                  child: Image.asset('assets/images/bmc_logo.jpeg'),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BMC',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF1F2D44),
                        ),
                      ),
                      Text(
                        'Bintang Muda Center',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF647089),
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
                'MENU\nUTAMA',
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
                              : const Color(0xFF7A8497),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF4B566C),
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
              onTap: _logout,
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
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE7EBF2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, size: 16, color: Color(0xFF9AA3B2)),
                  SizedBox(width: 8),
                  Text(
                    'Cari...',
                    style: TextStyle(
                      color: Color(0xFFA0A9B7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF7D8797),
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
          const SizedBox(width: 12),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF6388FF),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'AD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentUser?.nama.isNotEmpty == true
                    ? _currentUser!.nama
                    : 'Admin BMC',
                style: const TextStyle(
                  color: Color(0xFF27344B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Administrator',
                style: TextStyle(color: Color(0xFF99A4B5), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more_rounded, size: 18),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B57E4), Color(0xFF2756F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332557E4),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 110,
            top: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: -12,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Selamat Datang, Admin! 👋',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 33,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Berikut adalah ringkasan informasi terkini dari sistem manajemen BMC - Kamis, 19 Maret 2026.',
                style: TextStyle(color: Color(0xFFD9E4FF), fontSize: 12),
              ),
            ],
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
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: e.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE6EBF2)),
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
                                color: Color(0xFF667287),
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              e.value,
                              style: const TextStyle(
                                color: Color(0xFF1E2B3D),
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              e.subtitle,
                              style: const TextStyle(
                                color: Color(0xFFA1ABBC),
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: e.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(e.icon, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFF6400),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pendaftaran Menunggu Verifikasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '3 pendaftaran belum diverifikasi',
                  style: TextStyle(color: Color(0xFFFFD5BC), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                const _TableHeaderRow(
                  columns: [
                    'NAMA SISWA',
                    'SEKOLAH',
                    'KELAS',
                    'TANGGAL',
                    'STATUS',
                    'AKSI',
                  ],
                ),
                const SizedBox(height: 6),
                for (final row in _pendingRows)
                  _PendingItemRow(row: row, onApprove: () {}, onReject: () {}),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 0, 12),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/payment-verification');
                },
                child: const Text(
                  'Lihat Detail',
                  style: TextStyle(
                    color: Color(0xFFFF6400),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: const BoxDecoration(
              color: Color(0xFF2A58E8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal Belajar Hari Ini',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sabtu, 28 Maret 2026 — total 4 sesi',
                        style: TextStyle(
                          color: Color(0xFFC9D7FF),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('+ Tambah Jadwal'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('Lihat semua >'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Column(
              children: [
                const _TableHeaderRow(
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
                const SizedBox(height: 6),
                for (final row in _scheduleRows) _ScheduleItemRow(row: row),
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
    required this.name,
    required this.school,
    required this.className,
    required this.date,
    required this.status,
  });

  final String name;
  final String school;
  final String className;
  final String date;
  final String status;
}

class _ScheduleRow {
  const _ScheduleRow({
    required this.time,
    required this.className,
    required this.subject,
    required this.mentor,
    required this.room,
    required this.status,
  });

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
        border: Border(bottom: BorderSide(color: Color(0xFFF0F3F8))),
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
                color: _statusColor(row.status).withValues(alpha: 0.14),
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
  const _ScheduleItemRow({required this.row});

  final _ScheduleRow row;

  @override
  Widget build(BuildContext context) {
    final isActive = row.status == 'Berlangsung';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F3F8))),
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
                  color: const Color(0xFFE9F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  row.className,
                  style: const TextStyle(
                    color: Color(0xFF325CCF),
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
          const Expanded(
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 14, color: Color(0xFF4F82FF)),
                SizedBox(width: 8),
                Icon(Icons.delete_outline, size: 14, color: Color(0xFFEF4444)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
