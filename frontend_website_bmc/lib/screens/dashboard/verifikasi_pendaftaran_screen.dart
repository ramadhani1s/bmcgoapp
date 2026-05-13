import 'package:flutter/material.dart';

import '../../models/payment_verification_item.dart';
import '../../services/admin_dashboard_service.dart';

class VerifikasiPendaftaranScreen extends StatefulWidget {
  const VerifikasiPendaftaranScreen({super.key});

  @override
  State<VerifikasiPendaftaranScreen> createState() =>
      _VerifikasiPendaftaranScreenState();
}

class _VerifikasiPendaftaranScreenState
    extends State<VerifikasiPendaftaranScreen> {
  late Future<List<PaymentVerificationItem>> _futureItems;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _futureItems = AdminDashboardService.getPendingPaymentVerifications();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureItems = AdminDashboardService.getPendingPaymentVerifications();
    });
  }

  Future<void> _reload() async => _refresh();

  List<PaymentVerificationItem> _filterItems(
    List<PaymentVerificationItem> items,
  ) {
    if (_searchQuery.trim().isEmpty) return items;
    final query = _searchQuery.toLowerCase();
    return items.where((item) {
      return item.studentName.toLowerCase().contains(query) ||
          item.customerName.toLowerCase().contains(query) ||
          item.customerEmail.toLowerCase().contains(query) ||
          item.customerPhone.toLowerCase().contains(query) ||
          item.schoolName.toLowerCase().contains(query) ||
          item.className.toLowerCase().contains(query) ||
          item.packageTitle.toLowerCase().contains(query) ||
          item.transactionId.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _approveItem(PaymentVerificationItem item) async {
    try {
      await AdminDashboardService.approvePaymentVerification(item.transactionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil disetujui'),
          backgroundColor: Colors.green,
        ),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyetujui pendaftaran: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _approve(PaymentVerificationItem item) async => _approveItem(item);

  Future<void> _rejectItem(PaymentVerificationItem item) async {
    try {
      await AdminDashboardService.rejectPaymentVerification(item.transactionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil ditolak'),
          backgroundColor: Colors.red,
        ),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menolak pendaftaran: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reject(PaymentVerificationItem item) async => _rejectItem(item);

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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verifikasi Pendaftaran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDE4F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Cari nama, email, sekolah, paket, atau transaksi',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Muat Ulang'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: MediaQuery.of(context).size.height - 220,
            child: FutureBuilder<List<PaymentVerificationItem>>(
              future: _futureItems,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Gagal load data: ${snapshot.error}'),
                  );
                }

                final items = _filterItems(snapshot.data ?? const []);

                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada data verifikasi pending',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDDE4F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 2, child: Text('SISWA')),
                            Expanded(flex: 2, child: Text('KONTAK')),
                            Expanded(flex: 2, child: Text('SEKOLAH')),
                            Expanded(flex: 1, child: Text('PAKET')),
                            Expanded(flex: 1, child: Text('TANGGAL')),
                            Expanded(flex: 1, child: Text('STATUS')),
                            Expanded(flex: 1, child: Text('AKSI')),
                          ],
                        ),
                      ),
                      Flexible(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF6A00),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            item.studentName.isNotEmpty
                                                ? item.studentName[0].toUpperCase()
                                                : '-',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.studentName.isNotEmpty
                                                    ? item.studentName
                                                    : item.customerName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                item.customerEmail.isNotEmpty
                                                    ? item.customerEmail
                                                    : '-',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item.customerPhone.isNotEmpty
                                          ? item.customerPhone
                                          : '-',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      [item.schoolName, item.className]
                                          .where((value) => value.trim().isNotEmpty)
                                          .join(' - '),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      item.packageTitle.isNotEmpty
                                          ? item.packageTitle
                                          : '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2A58F2),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      _formatDate(item.createdAt),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.isVerified
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFFFEDD5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        item.isVerified ? 'Disetujui' : 'Menunggu',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: item.isVerified
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFFF97316),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Row(
                                      children: [
                                        InkWell(
                                          onTap: item.isVerified
                                              ? null
                                              : () => _approve(item),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: const Color(0xFF22C55E),
                                              ),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Color(0xFF22C55E),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: item.isVerified
                                              ? null
                                              : () => _reject(item),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: const Color(0xFFEF4444),
                                              ),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
