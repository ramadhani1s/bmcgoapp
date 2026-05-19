import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/payment_verification_item.dart';
import '../services/auth_service.dart';
import '../services/payment_verification_service.dart';

class PaymentVerificationScreen extends StatefulWidget {
  const PaymentVerificationScreen({super.key});

  @override
  State<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  static const Color _pageBg = Color(0xFFF1F4FA);
  static const Color _sidebarBg = Color(0xFFF8FAFD);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFDDE4F0);
  static const Color _primary = Color(0xFFFF6400);
  static const Color _green = Color(0xFF16A34A);
  static const Color _red = Color(0xFFEF4444);
  static const Color _blue = Color(0xFF2563EB);

  late Future<PaymentVerificationOverview> _overviewFuture;
  late Future<List<PaymentVerificationItem>> _itemsFuture;
  String _selectedFilter = 'pending';
  int _selectedMenuIndex = 1;

  List<_SideMenuItem> get _menuItems => const [
    _SideMenuItem(
      'Dashboard',
      Icons.grid_view_rounded,
      route: '/admin-dashboard',
    ),
    _SideMenuItem(
      'Verifikasi Pendaftaran',
      Icons.fact_check_outlined,
      route: '/payment-verification',
    ),
    _SideMenuItem(
      'Kelola Mentor',
      Icons.groups_2_outlined,
      route: '/mentor-management',
    ),
    _SideMenuItem('Kelola Jadwal', Icons.event_note_outlined),
    _SideMenuItem('Kelola Absensi', Icons.assignment_turned_in_outlined),
    _SideMenuItem('Kelola Pengumuman', Icons.campaign_outlined),
    _SideMenuItem('Kelola Paket Les', Icons.school_outlined),
    _SideMenuItem('Kelola Profil Alumni', Icons.badge_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _overviewFuture = PaymentVerificationService.getOverview();
    _itemsFuture = PaymentVerificationService.getVerifications(
      filter: _selectedFilter,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _overviewFuture = PaymentVerificationService.getOverview();
      _itemsFuture = PaymentVerificationService.getVerifications(
        filter: _selectedFilter,
      );
    });
  }

  void _setFilter(String filter) {
    if (_selectedFilter == filter) {
      return;
    }

    setState(() {
      _selectedFilter = filter;
      _itemsFuture = PaymentVerificationService.getVerifications(
        filter: _selectedFilter,
      );
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _onMenuTap(int index, _SideMenuItem item) {
    setState(() {
      _selectedMenuIndex = index;
    });

    if (item.route == null || item.route == '/payment-verification') {
      if (item.route == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menu "${item.title}" belum tersedia')),
        );
      }
      return;
    }

    Navigator.of(context).pushNamed(item.route!);
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dateTime.day.toString().padLeft(2, '0')} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String _getStatusLabel(PaymentVerificationItem item) {
    if (item.isVerified) return 'Disetujui';
    if (['failed', 'cancel', 'deny', 'expire'].contains(item.status)) {
      return 'Ditolak';
    }
    return 'Menunggu';
  }

  String _filterTitle(String filter) {
    switch (filter) {
      case 'approved':
        return 'Disetujui';
      case 'all':
        return 'Riwayat Verifikasi';
      default:
        return 'Menunggu Verifikasi';
    }
  }

  String _filterEmptyMessage(String filter) {
    switch (filter) {
      case 'approved':
        return 'Belum ada pendaftaran yang disetujui.';
      case 'all':
        return 'Belum ada riwayat verifikasi.';
      default:
        return 'Belum ada pendaftaran yang menunggu verifikasi.';
    }
  }

  Color _getStatusColor(String label) {
    switch (label) {
      case 'Disetujui':
        return _green;
      case 'Ditolak':
        return _red;
      default:
        return const Color(0xFFFF8A00);
    }
  }

  Color _getStatusBgColor(String label) {
    switch (label) {
      case 'Disetujui':
        return const Color(0xFFEAF8EF);
      case 'Ditolak':
        return const Color(0xFFFFECEC);
      default:
        return const Color(0xFFFFF1E6);
    }
  }

  Future<void> _approve(PaymentVerificationItem item) async {
    try {
      final result = await PaymentVerificationService.verifyPayment(
        item.transactionId,
      );
      if (!mounted) return;

      final waMessage = result['whatsapp_message']?.toString() ?? '';
      final waNumber = result['whatsapp_number']?.toString() ?? '';

      // ignore: use_build_context_synchronously
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Template WhatsApp Siswa'),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    waNumber.isNotEmpty
                        ? 'Nomor tujuan: $waNumber'
                        : 'Nomor WhatsApp siswa belum tersedia.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pesan otomatis:',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(waMessage),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: waMessage));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Template WA disalin')),
                  );
                },
                child: const Text('Copy Pesan'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      );

      await _refresh();
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran diverifikasi, akun siswa aktif'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _reject(PaymentVerificationItem item) async {
    try {
      await PaymentVerificationService.rejectPayment(item.transactionId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil ditolak')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showDetailModal(PaymentVerificationItem item) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DetailModal(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
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
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 14),
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildStatsRow(),
                        const SizedBox(height: 20),
                        _buildFilterTabs(),
                        const SizedBox(height: 16),
                        _buildSearchBar(),
                        const SizedBox(height: 20),
                        _buildTableSection(),
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
        color: _sidebarBg,
        border: const Border(
          right: BorderSide(color: _border),
          top: BorderSide(color: _border),
          bottom: BorderSide(color: _border),
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
                  child: Image.asset('assets/images/BMC .png'),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BMC',
                        style: TextStyle(
                          color: Color(0xFF1E2A3E),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
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
                final isSelected = index == _selectedMenuIndex;
                return Padding(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => _onMenuTap(index, item),
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2A58F2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 15,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF8290A6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF4B5972),
                              ),
                            ),
                          ),
                        ],
                      ),
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
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE9EFF8)),
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
          const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF7D8797),
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
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Administrator',
                style: TextStyle(
                  color: Color(0xFF27344B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Admin BMC',
                style: TextStyle(color: Color(0xFF99A4B5), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description_outlined),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verifikasi Pendaftaran',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verifikasi pendaftaran siswa baru dan pembayaran',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return FutureBuilder<PaymentVerificationOverview>(
      future: _overviewFuture,
      builder: (context, snapshot) {
        final overview = snapshot.data;
        return Row(
          children: [
            _buildStatCard(
              'Menunggu Verifikasi',
              overview?.waiting.toString() ?? '0',
              const Color(0xFFFFF1E6),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Disetujui',
              overview?.approved.toString() ?? '0',
              const Color(0xFFEAF8EF),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Ditolak',
              overview?.rejected.toString() ?? '0',
              const Color(0xFFFFECEC),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF667287)),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, size: 16, color: Color(0xFF9AA3B2)),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Cari siswa berdasarkan nama atau sekolah...',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFFA0A9B7)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = const [
      MapEntry('pending', 'Pending'),
      MapEntry('approved', 'Disetujui'),
      MapEntry('all', 'History'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((entry) {
        final filter = entry.key;
        final label = entry.value;
        final selected = _selectedFilter == filter;

        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => _setFilter(filter),
          selectedColor: _primary,
          labelStyle: TextStyle(
            color: selected ? Colors.white : const Color(0xFF42526E),
            fontWeight: FontWeight.w700,
          ),
          backgroundColor: Colors.white,
          side: BorderSide(color: selected ? _primary : _border),
        );
      }).toList(),
    );
  }

  Widget _buildTableSection() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: const BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Text(
              _filterTitle(_selectedFilter),
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: FutureBuilder<List<PaymentVerificationItem>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Data verifikasi belum tersedia saat ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF94A0B4)),
                    ),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      _filterEmptyMessage(_selectedFilter),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF94A0B4)),
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildTableHeader(),
                    const SizedBox(height: 6),
                    Column(
                      children: items.map((item) {
                        return _buildTableRow(item);
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    const headers = [
      'SISWA',
      'KONTAK',
      'SEKOLAH & KELAS',
      'PAKET LES',
      'TANGGAL DAFTAR',
      'STATUS',
      'AKSI',
    ];

    return Row(
      children: headers.map((header) {
        return Expanded(
          child: Text(
            header,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9AA4B6),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTableRow(PaymentVerificationItem item) {
    final statusLabel = _getStatusLabel(item);
    final statusColor = _getStatusColor(statusLabel);
    final statusBgColor = _getStatusBgColor(statusLabel);
    final showActions = _selectedFilter == 'pending' && !item.isVerified;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0E6D8))),
      ),
      child: Row(
        children: [
          // SISWA
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.studentName.isNotEmpty
                        ? item.studentName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.studentName.isNotEmpty
                            ? item.studentName
                            : item.customerName,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.customerEmail,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF9AA4B6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // KONTAK
          Expanded(
            child: Text(
              item.customerPhone,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // SEKOLAH & KELAS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.schoolName,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.className,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9AA4B6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // PAKET LES
          Expanded(
            child: Text(
              item.packageTitle,
              style: const TextStyle(fontSize: 12, color: _blue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // TANGGAL DAFTAR
          Expanded(
            child: Text(
              _formatDate(item.createdAt),
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // STATUS
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 70, // Reduced from 92 to 70 for shorter status container
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // AKSI
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: showActions ? 102 : 34,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (showActions) ...[
                      _actionChip(
                        icon: Icons.check,
                        color: _green,
                        onTap: () => _approve(item),
                        tooltip: 'Setujui',
                      ),
                      _actionChip(
                        icon: Icons.close,
                        color: _red,
                        onTap: () => _reject(item),
                        tooltip: 'Tolak',
                      ),
                    ],
                    _actionChip(
                      icon: Icons.visibility_outlined,
                      color: _blue,
                      onTap: () => _showDetailModal(item),
                      tooltip: 'Lihat Detail',
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

  Widget _actionChip({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 30,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withAlpha((0.55 * 255).round())),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: color),
          ),
        ),
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

class _DetailModal extends StatefulWidget {
  final PaymentVerificationItem item;

  const _DetailModal({required this.item});

  @override
  State<_DetailModal> createState() => _DetailModalState();
}

class _DetailModalState extends State<_DetailModal> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: _buildStepContent(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const stepNames = ['Data Siswa', 'Paket & Pembayaran', 'Data Orang Tua'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF97373),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Registrasi Siswa Baru',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                splashRadius: 18,
              ),
            ],
          ),
          Text(
            stepNames[_currentStep],
            style: const TextStyle(color: Color(0xFFFFF1F1), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (index) {
              final isActive = index <= _currentStep;
              final color = isActive
                  ? (index == _currentStep
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF16A34A))
                  : const Color(0xFFF5A0A0);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 3,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDataSiswa();
      case 1:
        return _buildPaketPembayaran();
      case 2:
        return _buildDataOrangTua();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDataSiswa() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _detailField('Nama Lengkap Siswa', widget.item.studentName),
        const SizedBox(height: 12),
        _detailField('Kelas', widget.item.className),
        const SizedBox(height: 12),
        _detailField('Asal Sekolah', widget.item.schoolName),
        const SizedBox(height: 12),
        _detailField(
          'No. WhatsApp Siswa',
          widget.item.registeredWhatsApp.isNotEmpty
              ? widget.item.registeredWhatsApp
              : widget.item.customerPhone,
        ),
        const SizedBox(height: 12),
        _detailField('Alamat Lengkap Siswa', widget.item.address),
      ],
    );
  }

  Widget _buildPaketPembayaran() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailField('Paket Les Dipilih', widget.item.packageTitle),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bukti Tanda tangan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF27344B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD9E1EA)),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF9FBFD),
              ),
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur upload bukti akan datang'),
                    ),
                  );
                },
                child: const Text('Lihat Bukti Tanda Tangan'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _detailField('Status Verifikasi', 'Menunggu'),
        const SizedBox(height: 12),
        _detailField('Tanggal Daftar', _formatDate(widget.item.createdAt)),
      ],
    );
  }

  Widget _buildDataOrangTua() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _detailField('Nama Orang Tua', 'Belum tersedia'),
        const SizedBox(height: 12),
        _detailField('No. WhatsApp Orang Tua', 'Belum tersedia'),
      ],
    );
  }

  Widget _detailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF27344B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD9E1EA)),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF9FBFD),
          ),
          child: Text(value, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dateTime.day.toString().padLeft(2, '0')} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  Widget _buildFooter() {
    const steps = 3;
    final isLastStep = _currentStep == steps - 1;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              child: const Text('Kembali'),
            ),
          if (_currentStep > 0) const Spacer(),
          if (isLastStep)
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            )
          else
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep++;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97373),
              ),
              child: const Text(
                'Lanjut',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
