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
  List<PaymentVerificationItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final data =
          await AdminDashboardService.getPendingPaymentVerifications();

      if (!mounted) return;

      setState(() {
        _items = data;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal load data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      'Des'
    ];
    return months[month - 1];
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

          /// TABLE CONTAINER
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDE4F0)),
            ),
            child: Column(
              children: [
                /// HEADER
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: Text('SISWA')),
                      Expanded(flex: 1, child: Text('KONTAK')),
                      Expanded(flex: 2, child: Text('SEKOLAH')),
                      Expanded(flex: 1, child: Text('PAKET')),
                      Expanded(flex: 1, child: Text('TANGGAL')),
                      Expanded(flex: 1, child: Text('STATUS')),
                      Expanded(flex: 1, child: Text('AKSI')),
                    ],
                  ),
                ),

                /// CONTENT
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  )
                else if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Tidak ada data',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  for (final item in _items)
                    _buildRow(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(PaymentVerificationItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0E6D8)),
        ),
      ),
      child: Row(
        children: [
          /// 👤 SISWA
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      (item as dynamic).email ?? '-',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// 📞 KONTAK
          Expanded(
            flex: 1,
            child: Text(
              (item as dynamic).phone ?? '-',
              style: const TextStyle(fontSize: 12),
            ),
          ),

          /// 🏫 SEKOLAH
          Expanded(
            flex: 2,
            child: Text(
              '${item.schoolName} - ${item.className}',
              style: const TextStyle(fontSize: 12),
            ),
          ),

          /// 📚 PAKET
          Expanded(
            flex: 1,
            child: Text(
              (item as dynamic).packageName ?? '-',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2A58F2),
              ),
            ),
          ),

          /// 📅 TANGGAL
          Expanded(
            flex: 1,
            child: Text(
              '${item.createdAt.day.toString().padLeft(2, '0')} '
              '${_monthName(item.createdAt.month)} '
              '${item.createdAt.year}',
              style: const TextStyle(fontSize: 12),
            ),
          ),

          /// 📊 STATUS
          Expanded(
            flex: 1,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

          /// ⚡ AKSI
          Expanded(
            flex: 1,
            child: Row(
              children: [
                /// APPROVE
                InkWell(
                  onTap: item.isVerified
                      ? null
                      : () async {
                          await AdminDashboardService
                              .approvePaymentVerification(
                                  item.transactionId);
                          _loadData();
                        },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFF22C55E)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.check,
                        size: 16, color: Color(0xFF22C55E)),
                  ),
                ),

                const SizedBox(width: 6),

                /// REJECT
                InkWell(
                  onTap: item.isVerified
                      ? null
                      : () async {
                          await AdminDashboardService
                              .rejectPaymentVerification(
                                  item.transactionId);
                          _loadData();
                        },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFFEF4444)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close,
                        size: 16, color: Color(0xFFEF4444)),
                  ),
                ),

                const SizedBox(width: 6),

                /// DETAIL
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/payment-verification',
                      arguments: item,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFF3B82F6)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.remove_red_eye,
                        size: 16, color: Color(0xFF3B82F6)),
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