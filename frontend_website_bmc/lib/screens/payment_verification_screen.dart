import 'package:flutter/material.dart';

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
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE6EDF7);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _green = Color(0xFF16A34A);
  static const Color _red = Color(0xFFEF4444);
  static const Color _amber = Color(0xFFF59E0B);

  late Future<PaymentVerificationOverview> _overviewFuture;
  late Future<List<PaymentVerificationItem>> _itemsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _overviewFuture = PaymentVerificationService.getOverview();
    _itemsFuture = PaymentVerificationService.getVerifications(
      filter: _selectedFilter,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _overviewFuture = PaymentVerificationService.getOverview();
      _itemsFuture = PaymentVerificationService.getVerifications(
        filter: _selectedFilter,
      );
    });
  }

  void _setFilter(String filter) {
    if (_selectedFilter == filter) return;
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

  String _monthName(int month) {
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
    return months[month - 1];
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')} ${_monthName(dateTime.month)} ${dateTime.year}';
  }

  String _statusLabel(PaymentVerificationItem item) {
    if (item.isVerified) return 'Disetujui';
    if (['failed', 'cancel', 'deny', 'expire'].contains(item.status)) {
      return 'Ditolak';
    }
    return 'Menunggu';
  }

  Color _statusColor(String label) {
    switch (label) {
      case 'Disetujui':
        return _green;
      case 'Ditolak':
        return _red;
      default:
        return _amber;
    }
  }

  Color _statusBgColor(String label) {
    switch (label) {
      case 'Disetujui':
        return const Color(0xFFEAF8EF);
      case 'Ditolak':
        return const Color(0xFFFFECEC);
      default:
        return const Color(0xFFFFF1E6);
    }
  }

  List<PaymentVerificationItem> _filterItems(
    List<PaymentVerificationItem> items,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;

    return items.where((item) {
      return item.studentName.toLowerCase().contains(query) ||
          item.schoolName.toLowerCase().contains(query) ||
          item.className.toLowerCase().contains(query) ||
          item.transactionId.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _approve(PaymentVerificationItem item) async {
    try {
      await PaymentVerificationService.verifyPayment(item.transactionId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil disetujui'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyetujui pembayaran: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reject(PaymentVerificationItem item) async {
    try {
      await PaymentVerificationService.rejectPayment(item.transactionId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil ditolak'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menolak pembayaran: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _delete(PaymentVerificationItem item) async {
    try {
      await PaymentVerificationService.deletePayment(item.transactionId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDetailModal(PaymentVerificationItem item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Verifikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama Siswa: ${item.studentName.isEmpty ? '-' : item.studentName}'),
            const SizedBox(height: 8),
            Text('Sekolah: ${item.schoolName.isEmpty ? '-' : item.schoolName}'),
            const SizedBox(height: 8),
            Text('Kelas: ${item.className.isEmpty ? '-' : item.className}'),
            const SizedBox(height: 8),
            Text('Tanggal: ${_formatDate(item.createdAt)}'),
            const SizedBox(height: 8),
            Text('Status: ${_statusLabel(item)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
  String title,
  int value,
  Color color,
  Color backgroundColor,
  IconData icon,
) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
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
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$value',
                  style: TextStyle(
                    color: color,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
            ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 24, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Cari berdasarkan nama, sekolah, kelas, atau transaksi...',
                hintStyle: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final selected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _setFilter(filter),
      selectedColor: _primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF42526E),
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: selected ? _primary : const Color(0xFFE5E7EB)),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                'NAMA SISWA',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'SEKOLAH',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'KELAS',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'TANGGAL',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'STATUS',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'AKSI',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildTableRow(PaymentVerificationItem item) {
    final statusLabel = _statusLabel(item);
    final statusColor = _statusColor(statusLabel);
    final statusBgColor = _statusBgColor(statusLabel);
    final showActions = _selectedFilter == 'pending' && !item.isVerified;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0E6D8))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.studentName.isNotEmpty ? item.studentName : item.customerName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              item.schoolName.isEmpty ? '-' : item.schoolName,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              item.className.isEmpty ? '-' : item.className,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              _formatDate(item.createdAt),
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 70,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                      color: _primary,
                      onTap: () => _showDetailModal(item),
                      tooltip: 'Lihat Detail',
                    ),
                    _actionChip(
                      icon: Icons.delete_outline,
                      color: _red,
                      onTap: () => _delete(item),
                      tooltip: 'Hapus',
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

  Widget _buildTableSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Verifikasi Pendaftaran',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Data ditampilkan secara dinamis',
                  style: const TextStyle(color: Color(0xFFDBEAFE), fontSize: 13),
                ),
              ],
            ),
          ),
          FutureBuilder<List<PaymentVerificationItem>>(
            future: _itemsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('Gagal memuat data')),
                );
              }

              final allItems = snapshot.data ?? [];
              final items = _filterItems(allItems);

              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      _selectedFilter == 'approved'
                          ? 'Belum ada pendaftaran yang disetujui.'
                          : _selectedFilter == 'all'
                              ? 'Belum ada riwayat verifikasi.'
                              : 'Belum ada pendaftaran yang menunggu verifikasi.',
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  _buildTableHeader(),
                  for (final item in items) _buildTableRow(item),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.15),
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
                          children: const [
                            Text(
                              'Kelola Verifikasi Pendaftaran',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Verifikasi pembayaran dan pendaftaran siswa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.verified_user,
                        color: Colors.white,
                        size: 64,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                FutureBuilder<PaymentVerificationOverview>(
                  future: _overviewFuture,
                  builder: (context, snapshot) {
                    final overview = snapshot.data ??
                        const PaymentVerificationOverview(
                          waiting: 0,
                          approved: 0,
                          rejected: 0,
                          items: [],
                        );
                    return Row(
                      children: [
                        _buildStatCard(
                          'Menunggu Verifikasi',
                          overview.waiting,
                          const Color(0xFFF59E0B),
                          const Color(0xFFFFF1E6),
                          Icons.pending_actions,
                        ),

                        const SizedBox(width: 14),

                        _buildStatCard(
                          'Disetujui',
                          overview.approved,
                          const Color(0xFF16A34A),
                          const Color(0xFFEAF8EF),
                          Icons.check_circle,
                        ),

                        const SizedBox(width: 14),

                        _buildStatCard(
                          'Ditolak',
                          overview.rejected,
                          const Color(0xFFEF4444),
                          const Color(0xFFFFECEC),
                          Icons.cancel,
                        ),
                      ],
                    );
                  },
                ),
                Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: const Color(0xFFE6EDF7),
    ),
  ),
  child: Row(
    children: [
      Expanded(
        flex: 2,
        child: _buildSearchBar(),
      ),

      const SizedBox(width: 12),

                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    decoration: InputDecoration(
                      labelText: 'Filter Status',
                      prefixIcon: const Icon(
                        Icons.filter_alt_outlined,
                        color: Color(0xFF2563EB),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Menunggu'),
                      ),
                      DropdownMenuItem(
                        value: 'approved',
                        child: Text('Disetujui'),
                      ),
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('Semua Data'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _setFilter(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
                _buildTableSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}