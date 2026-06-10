import 'package:flutter/material.dart';

import '../../models/payment_verification_item.dart';
import '../../services/admin_dashboard_service.dart';
import '../../services/payment_verification_service.dart';

class VerifikasiPendaftaranScreen extends StatefulWidget {
  const VerifikasiPendaftaranScreen({super.key});

  @override
  State<VerifikasiPendaftaranScreen> createState() =>
      _VerifikasiPendaftaranScreenState();
}

class _VerifikasiPendaftaranScreenState
    extends State<VerifikasiPendaftaranScreen> {
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE6EDF7);
  static const Color _textSecondary = Color(0xFF6B7280);

  late Future<PaymentVerificationOverview> _future;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<PaymentVerificationOverview> _loadData() async {
    try {
      return await PaymentVerificationService.getOverview();
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _future = PaymentVerificationService.getOverview();
    });
  }

  String _monthName(int month) {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return months[month - 1];
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')} ${_monthName(dateTime.month)} ${dateTime.year}';
  }

  // ── Status helpers (sama persis kayak dashboard) ──────────────────────────
  String _statusLabel(PaymentVerificationItem item) {
    if (item.isVerified) return '✓ Disetujui';
    if (['failed', 'cancel', 'deny', 'expire'].contains(item.status)) return '✗ Ditolak';
    return '⏳ Menunggu';
  }

  Color _statusColor(PaymentVerificationItem item) {
    if (item.isVerified) return const Color(0xFF16A34A);
    if (item.status == 'success') return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  Color _statusBgColor(PaymentVerificationItem item) {
    if (item.isVerified) return const Color(0xFFECFDF3);
    if (item.status == 'success') return const Color(0xFFFFF7ED);
    return const Color(0xFFFEF2F2);
  }
  // ─────────────────────────────────────────────────────────────────────────

  List<PaymentVerificationItem> _filterItems(List<PaymentVerificationItem> items) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items.where((item) =>
      item.studentName.toLowerCase().contains(query) ||
      item.schoolName.toLowerCase().contains(query) ||
      item.className.toLowerCase().contains(query) ||
      item.transactionId.toLowerCase().contains(query),
    ).toList();
  }

  Future<void> _approve(PaymentVerificationItem item) async {
    try {
      await AdminDashboardService.approvePaymentVerification(item.transactionId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran berhasil disetujui'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyetujui pendaftaran: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reject(PaymentVerificationItem item) async {
    try {
      await AdminDashboardService.rejectPaymentVerification(item.transactionId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran berhasil ditolak'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menolak pendaftaran: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Cari berdasarkan nama, sekolah, kelas, atau transaksi...',
        prefixIcon: const Icon(Icons.search, size: 24, color: Color(0xFF64748B)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4)),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        hintStyle: const TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
      ),
      style: const TextStyle(fontSize: 15, color: Color(0xFF27344B), fontWeight: FontWeight.w500),
    );
  }

  // ── Stat card (sama kayak dashboard) ─────────────────────────────────────
  Widget _statCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: color)),
                  const SizedBox(height: 2),
                ],
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  // ── Table header ──────────────────────────────────────────────────────────
  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _headerCell('NAMA SISWA', flex: 2),
          _headerCell('SEKOLAH'),
          _headerCell('KELAS'),
          _headerCell('TANGGAL'),
          _headerCell('STATUS'),
          _headerCell('AKSI'),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF9AA4B6), fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ── Table row ─────────────────────────────────────────────────────────────
  Widget _buildRow(PaymentVerificationItem item) {
    final status = _statusLabel(item);
    final canAct = !item.isVerified && item.status == 'success';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0E6D8))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nama
          Expanded(
            flex: 2,
            child: Text(
              item.studentName.isEmpty ? '-' : item.studentName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Sekolah
          Expanded(
            child: Text(
              item.schoolName.isEmpty ? '-' : item.schoolName,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Kelas
          Expanded(
            child: Text(
              item.className.isEmpty ? '-' : item.className,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Tanggal
          Expanded(
            child: Text(
              _formatDate(item.createdAt),
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Status badge (sama persis kayak dashboard)
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBgColor(item),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _statusColor(item).withValues(alpha: 0.35)),
                ),
                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _statusColor(item),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          // Aksi (sama persis kayak dashboard, tanpa icon mata)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 62,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: canAct ? () => _approve(item) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Setuju'),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 52,
                  height: 28,
                  child: OutlinedButton(
                    onPressed: canAct ? () => _reject(item) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Table container ───────────────────────────────────────────────────────
  Widget _buildTable(List<PaymentVerificationItem> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(15, 23, 42, 0.05), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Header card biru
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data Pendaftaran', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Daftar siswa yang menunggu verifikasi', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 13)),
              ],
            ),
          ),
          _buildTableHeader(),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada data pendaftaran.',
                  style: TextStyle(color: _textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            for (final item in items) _buildRow(item),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7F9FF), Color(0xFFF3F6FB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: FutureBuilder<PaymentVerificationOverview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Gagal memuat data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textSecondary)),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _textSecondary)),
                  ],
                ),
              ),
            );
          }

          final overview = snapshot.data ??
              const PaymentVerificationOverview(waiting: 0, approved: 0, rejected: 0, items: []);
          final filtered = _filterItems(overview.items);

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verifikasi Pendaftaran',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF111827), letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Verifikasi pembayaran dan pendaftaran siswa secara real-time',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _statCard('Menunggu', overview.waiting.toString(), const Color(0xFFF97316), Icons.pending_actions),
                      _statCard('Disetujui', overview.approved.toString(), const Color(0xFF16A34A), Icons.check_circle),
                      _statCard('Ditolak', overview.rejected.toString(), const Color(0xFFDC2626), Icons.cancel),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 22),
                  _buildTable(filtered),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}