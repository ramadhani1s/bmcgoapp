import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:frontend_mobile_bmc/models/payment_model.dart';
import 'package:frontend_mobile_bmc/services/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  static const Color _blueHeader = Color(0xFF2D4CC8);

  String _selectedFilter = 'all';
  Future<List<PaymentHistoryItem>> _future = Future.value(const []);

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) {
        _future = _loadData();
        setState(() {});
      }
    });
  }

  Future<List<PaymentHistoryItem>> _loadData() {
    final status = _selectedFilter == 'all' ? null : _selectedFilter;
    return PaymentService.getPaymentHistory(status: status);
  }

  void _refresh() {
    setState(() {
      _future = _loadData();
    });
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return 'Berhasil';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Gagal';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return const Color(0xFF1E8E3E);
      case 'pending':
        return const Color(0xFFF39C12);
      case 'failed':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatRupiah(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        backgroundColor: _blueHeader,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _selectedFilter == 'all',
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = 'all';
                      _future = _loadData();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Pending'),
                  selected: _selectedFilter == 'pending',
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = 'pending';
                      _future = _loadData();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Berhasil'),
                  selected: _selectedFilter == 'success',
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = 'success';
                      _future = _loadData();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Gagal'),
                  selected: _selectedFilter == 'failed',
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = 'failed';
                      _future = _loadData();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PaymentHistoryItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _refresh,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final data = snapshot.data ?? const [];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Belum ada riwayat pembayaran.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final color = _statusColor(item.status);

                    return Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.packageTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: (0.12 * 255).round()),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    _statusLabel(item.status),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_formatRupiah(item.amount)),
                            const SizedBox(height: 6),
                            Text(
                              'Tipe: ${item.paymentType == '-' || item.paymentType.isEmpty ? 'Belum terisi' : item.paymentType}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Transaksi: ${item.transactionId}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Dibuat: ${_formatDate(item.createdAt)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Diupdate: ${_formatDate(item.updatedAt)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
