import 'package:flutter/material.dart';

import '../../models/payment_verification_item.dart';
import '../../services/payment_verification_service.dart';

class VerifikasiPendaftaranScreen extends StatefulWidget {
  const VerifikasiPendaftaranScreen({super.key});

  @override
  State<VerifikasiPendaftaranScreen> createState() =>
      _VerifikasiPendaftaranScreenState();
}

class _VerifikasiPendaftaranScreenState
    extends State<VerifikasiPendaftaranScreen> {
  List<PaymentVerificationItem> pendaftaranList = [];
  List<PaymentVerificationItem> filteredList = [];
  final Set<String> selectedTransactionIds = <String>{};
  bool isLoading = false;
  bool isBulkProcessing = false;
  int pendingCount = 0;
  int approvedCount = 0;
  int rejectedCount = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPendaftaran();
  }

  Future<void> _loadPendaftaran() async {
    setState(() => isLoading = true);
    try {
      final overview = await PaymentVerificationService.getOverview();
      if (mounted) {
        setState(() {
          pendaftaranList = overview.items;
          filteredList = overview.items;
          selectedTransactionIds.removeWhere(
            (id) => !overview.items.any((item) => item.transactionId == id),
          );
          // Pending = belum diverifikasi (baik status success atau lainnya)
          pendingCount = overview.items
              .where((item) => !item.isVerified)
              .length;
          // Approved = sudah diverifikasi
          approvedCount =
              overview.items.where((item) => item.isVerified).length;
          // Rejected = (untuk info saja, tidak perlu ditampilkan)
          rejectedCount = 0;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        final errorMsg = e.toString().contains('Token')
            ? '❌ Sesi Anda sudah expired. Silakan login ulang.'
            : '❌ Gagal memuat data: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _filterData(String value) {
    final keyword = value.trim().toLowerCase();
    setState(() {
      if (keyword.isEmpty) {
        filteredList = pendaftaranList;
        return;
      }

      filteredList = pendaftaranList.where((item) {
        return item.studentName.toLowerCase().contains(keyword) ||
            item.schoolName.toLowerCase().contains(keyword) ||
            item.className.toLowerCase().contains(keyword) ||
            item.customerPhone.toLowerCase().contains(keyword);
      }).toList();
    });
  }

  bool _isAllFilteredSelected() {
    if (filteredList.isEmpty) {
      return false;
    }
    return filteredList
        .every((item) => selectedTransactionIds.contains(item.transactionId));
  }

  void _toggleSelectAllFiltered(bool checked) {
    setState(() {
      if (checked) {
        selectedTransactionIds
            .addAll(filteredList.map((item) => item.transactionId));
      } else {
        for (final item in filteredList) {
          selectedTransactionIds.remove(item.transactionId);
        }
      }
    });
  }

  void _toggleSelectOne(PaymentVerificationItem item, bool checked) {
    setState(() {
      if (checked) {
        selectedTransactionIds.add(item.transactionId);
      } else {
        selectedTransactionIds.remove(item.transactionId);
      }
    });
  }

  Future<void> _runBulkAction(
    String label,
    Future<void> Function(PaymentVerificationItem item) action,
  ) async {
    if (selectedTransactionIds.isEmpty || isBulkProcessing) {
      return;
    }

    final selectedItems = pendaftaranList
        .where((item) => selectedTransactionIds.contains(item.transactionId))
        .toList();

    setState(() => isBulkProcessing = true);
    var successCount = 0;
    var failedCount = 0;

    for (final item in selectedItems) {
      try {
        await action(item);
        successCount++;
      } catch (_) {
        failedCount++;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isBulkProcessing = false;
      selectedTransactionIds.clear();
    });

    await _loadPendaftaran();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label selesai. Berhasil: $successCount, Gagal: $failedCount',
        ),
        backgroundColor: failedCount == 0 ? Colors.green : Colors.orange,
      ),
    );
  }

  Future<void> _bulkApprove() async {
    await _runBulkAction('Terima semua', (item) async {
      if (!item.isVerified) {
        await PaymentVerificationService.verifyPayment(item.transactionId);
      }
    });
  }

  Future<void> _bulkReject() async {
    await _runBulkAction('Tolak semua', (item) async {
      if (!item.isVerified) {
        await PaymentVerificationService.rejectPayment(item.transactionId);
      }
    });
  }

  Future<void> _bulkDelete() async {
    await _runBulkAction('Hapus semua', (item) async {
      await PaymentVerificationService.deletePayment(item.transactionId);
    });
  }

  String _statusLabel(PaymentVerificationItem item) {
    if (item.isVerified) {
      return '✓ Disetujui';
    }
    if (item.status == 'success') {
      return '⏳ Menunggu';
    }
    return '✗ Ditolak';
  }

  Color _statusColor(PaymentVerificationItem item) {
    if (item.isVerified) {
      return const Color(0xFF16A34A); // Hijau (Disetujui)
    }
    if (item.status == 'success') {
      return const Color(0xFFF97316); // Orange (Menunggu)
    }
    return const Color(0xFFEF4444); // Merah (Ditolak)
  }

  void _showDetailSiswa(PaymentVerificationItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Data Siswa'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nama: ${item.studentName}'),
              const SizedBox(height: 8),
              Text('Email: ${item.customerEmail}'),
              const SizedBox(height: 8),
              Text('WhatsApp: ${item.customerPhone.isEmpty ? '-' : item.customerPhone}'),
              const SizedBox(height: 8),
              Text('Sekolah: ${item.schoolName.isEmpty ? '-' : item.schoolName}'),
              const SizedBox(height: 8),
              Text('Kelas: ${item.className.isEmpty ? '-' : item.className}'),
              const SizedBox(height: 8),
              Text('Alamat: ${item.address.isEmpty ? '-' : item.address}'),
              const SizedBox(height: 8),
              Text('Paket: ${item.packageTitle}'),
              const SizedBox(height: 8),
              Text('Nominal: Rp${item.amount}'),
              const SizedBox(height: 8),
              Text('Status: ${_statusLabel(item)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    int value,
    Color bg,
    Color border,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: TextStyle(
                color: textColor,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: tooltip,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: disabled ? const Color(0xFFE5E7EB) : color,
            foregroundColor: Colors.white,
          ),
          child: Icon(icon, size: 14),
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildBulkActionBar() {
    if (selectedTransactionIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          Text(
            '${selectedTransactionIds.length} data dipilih',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9A3412),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: isBulkProcessing ? null : _bulkApprove,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Terima Semua'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: isBulkProcessing ? null : _bulkReject,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Tolak Semua'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: isBulkProcessing ? null : _bulkDelete,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7280),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(PaymentVerificationItem item) {
    final pendingApproval = item.status == 'success' && !item.isVerified;
    final statusColor = _statusColor(item);
    final statusLabel = _statusLabel(item);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Checkbox(
              value: selectedTransactionIds.contains(item.transactionId),
              onChanged: (value) => _toggleSelectOne(item, value ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          SizedBox(
            width: 210,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5A00),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    item.studentName.isEmpty
                        ? '?'
                        : item.studentName.trim().split(' ').take(2).map((e) => e.isEmpty ? '' : e[0]).join().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.customerEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              item.customerPhone.isEmpty ? '-' : item.customerPhone,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
            ),
          ),
          SizedBox(
            width: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.schoolName.isEmpty ? '-' : item.schoolName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 2),
                Text(
                  item.className.isEmpty ? '-' : item.className,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              item.packageTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              '${item.createdAt.day.toString().padLeft(2, '0')} ${_monthLabel(item.createdAt.month)} ${item.createdAt.year}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
            ),
          ),
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusColor.withOpacity(0.35)),
              ),
              child: Text(
                statusLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.check,
                  color: const Color(0xFF16A34A),
                  tooltip: 'Setujui pembayaran',
                  onTap: pendingApproval ? () => _verifyPendaftaran(item) : null,
                ),
                _buildActionButton(
                  icon: Icons.close,
                  color: const Color(0xFFEF4444),
                  tooltip: 'Tolak pembayaran',
                  onTap: pendingApproval ? () => _rejectPendaftaran(item) : null,
                ),
                _buildActionButton(
                  icon: Icons.remove_red_eye_outlined,
                  color: const Color(0xFF3B82F6),
                  tooltip: 'Lihat detail siswa',
                  onTap: () => _showDetailSiswa(item),
                ),
                _buildActionButton(
                  icon: Icons.delete_outline,
                  color: const Color(0xFF6B7280),
                  tooltip: 'Hapus data ini',
                  onTap: () async {
                    try {
                      await PaymentVerificationService.deletePayment(
                        item.transactionId,
                      );
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data berhasil dihapus'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadPendaftaran();
                    } catch (e) {
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menghapus: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthLabel(int month) {
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
    if (month < 1 || month > 12) {
      return '-';
    }
    return months[month - 1];
  }

  void _verifyPendaftaran(PaymentVerificationItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("✅ Terima Pendaftaran"),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Nama: ${item.studentName}"),
            Text("Sekolah: ${item.schoolName}"),
            Text("Kelas: ${item.className}"),
            Text("Nominal: Rp${item.amount.toString()}"),
            const SizedBox(height: 16),
            const Text("Apakah Anda yakin ingin menerima pendaftaran ini?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await PaymentVerificationService.verifyPayment(
                  item.transactionId,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Pendaftaran diterima"),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadPendaftaran();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Gagal: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Terima", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _rejectPendaftaran(PaymentVerificationItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("❌ Tolak Pendaftaran"),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Nama: ${item.studentName}"),
            Text("Sekolah: ${item.schoolName}"),
            Text("Kelas: ${item.className}"),
            Text("Nominal: Rp${item.amount.toString()}"),
            const SizedBox(height: 16),
            const Text("Apakah Anda yakin ingin menolak pendaftaran ini?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await PaymentVerificationService.rejectPayment(
                  item.transactionId,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ Pendaftaran ditolak"),
                    backgroundColor: Colors.red,
                  ),
                );
                _loadPendaftaran();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Gagal: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Tolak", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                color: Color(0xFFFF5A00),
                size: 24,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verifikasi Pendaftaran',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Verifikasi pendaftaran siswa baru dan pembayaran',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadPendaftaran,
                tooltip: 'Refresh data',
                icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _buildStatCard(
                'Menunggu Verifikasi',
                pendingCount,
                const Color(0xFFFFF7ED),
                const Color(0xFFFED7AA),
                const Color(0xFFB45309),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Disetujui',
                approvedCount,
                const Color(0xFFECFDF3),
                const Color(0xFFA7F3D0),
                const Color(0xFF15803D),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Ditolak',
                rejectedCount,
                const Color(0xFFFEF2F2),
                const Color(0xFFFECACA),
                const Color(0xFFB91C1C),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildBulkActionBar(),

          const SizedBox(height: 4),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterData,
                    decoration: const InputDecoration(
                      hintText: 'Cari siswa berdasarkan nama atau sekolah...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: filteredList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Tidak ada data pendaftaran",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Semua pembayaran sudah diverifikasi atau menunggu pembayaran dari siswa",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadPendaftaran,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5A00),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Daftar Pendaftaran',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 920,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                color: const Color(0xFFF8FAFC),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 34,
                                      child: Checkbox(
                                        value: _isAllFilteredSelected(),
                                        onChanged: (value) => _toggleSelectAllFiltered(value ?? false),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    _buildTableHeaderCell('SISWA', 210),
                                    _buildTableHeaderCell('KONTAK', 110),
                                    _buildTableHeaderCell('SEKOLAH & KELAS', 130),
                                    _buildTableHeaderCell('PAKET LES', 140),
                                    _buildTableHeaderCell('TANGGAL DAFTAR', 90),
                                    _buildTableHeaderCell('STATUS', 80),
                                    _buildTableHeaderCell('AKSI', 130),
                                  ],
                                ),
                              ),
                              ...filteredList.map(_buildTableRow),
                            ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
