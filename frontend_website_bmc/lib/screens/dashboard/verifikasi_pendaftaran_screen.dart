import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/payment_verification_item.dart';
import '../../services/admin_dashboard_service.dart';

class VerifikasiPendaftaranScreen extends StatefulWidget {
  const VerifikasiPendaftaranScreen({super.key});

  @override
  State<VerifikasiPendaftaranScreen> createState() => _VerifikasiPendaftaranScreenState();
}

class _VerifikasiPendaftaranScreenState extends State<VerifikasiPendaftaranScreen> {
  Future<List<PaymentVerificationItem>>? _futureItems;
  List<PaymentVerificationItem> _items = [];
  List<PaymentVerificationItem> _filtered = [];
  final TextEditingController _searchController = TextEditingController();
  bool _loadingAction = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _futureItems = AdminDashboardService.getPendingPaymentVerifications();
    _searchController.addListener(_onSearchChanged);
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        _reload();
      }
    });
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(_items);
      } else {
        _filtered = _items.where((it) {
          return it.studentName.toLowerCase().contains(q) ||
              it.customerName.toLowerCase().contains(q) ||
              it.customerEmail.toLowerCase().contains(q) ||
              it.customerPhone.toLowerCase().contains(q) ||
              it.schoolName.toLowerCase().contains(q) ||
              it.className.toLowerCase().contains(q) ||
              it.packageTitle.toLowerCase().contains(q) ||
              it.transactionId.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Future<void> _reload() async {
    setState(() {
      _futureItems = AdminDashboardService.getPendingPaymentVerifications();
    });
    
    final items = await _futureItems;
    if (!mounted) return;
    setState(() {
      _items = items ?? [];
      _filtered = List.from(_items);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    final m = (d.month >= 1 && d.month <= 12) ? months[d.month - 1] : '-';
    return '${d.day.toString().padLeft(2, '0')} $m ${d.year}';
  }

  Future<void> _approve(PaymentVerificationItem item) async {
    setState(() => _loadingAction = true);
    try {
      await AdminDashboardService.approvePaymentVerification(item.transactionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran disetujui'), backgroundColor: Colors.green));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal approve: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loadingAction = false);
    }
  }

  Future<void> _reject(PaymentVerificationItem item) async {
    setState(() => _loadingAction = true);
    try {
      await AdminDashboardService.rejectPaymentVerification(item.transactionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran ditolak'), backgroundColor: Colors.red));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal reject: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loadingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: Color(0xFFFF5A00), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verifikasi Pendaftaran', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF111827), height: 1)),
                    SizedBox(height: 6),
                    Text('Verifikasi pendaftaran siswa baru dan pembayaran', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              SizedBox(width: 40, height: 40, child: IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Row(children: [
              const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _searchController, decoration: const InputDecoration(hintText: 'Cari nama, email, sekolah, paket, atau transaksi', border: InputBorder.none, isDense: true))),
            ]),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: MediaQuery.of(context).size.height - 220,
            child: FutureBuilder<List<PaymentVerificationItem>>(
              future: _futureItems,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Gagal load data: ${snapshot.error}'));

                final items = snapshot.data ?? [];
                if (_items.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _items = items;
                      _filtered = List.from(_items);
                    });
                  });
                }

                if (_filtered.isEmpty) return Center(child: Text('Tidak ada data verifikasi pending', style: TextStyle(color: Colors.grey.shade600)));

                return ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _filtered[index];
                    return ListTile(
                      title: Text(item.studentName.isNotEmpty ? item.studentName : item.customerName),
                      subtitle: Text('${item.packageTitle} • ${_formatDate(item.createdAt)}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(item.isVerified ? 'Disetujui' : (item.status == 'success' ? 'Menunggu' : 'Ditolak'), style: TextStyle(color: item.isVerified ? const Color(0xFF16A34A) : const Color(0xFFF97316))),
                        const SizedBox(width: 12),
                        SizedBox(width: 40, height: 40, child: IconButton(icon: const Icon(Icons.check, color: Color(0xFF16A34A)), onPressed: item.isVerified || _loadingAction ? null : () => _approve(item))),
                        SizedBox(width: 40, height: 40, child: IconButton(icon: const Icon(Icons.close, color: Color(0xFFEF4444)), onPressed: item.isVerified || _loadingAction ? null : () => _reject(item))),
                      ]),
                      onTap: () => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Detail'), content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('Nama: ${item.studentName}'), const SizedBox(height: 8), Text('Email: ${item.customerEmail}'), const SizedBox(height: 8), Text('Phone: ${item.customerPhone.isEmpty ? '-' : item.customerPhone}'), const SizedBox(height: 8), Text('Sekolah: ${item.schoolName.isEmpty ? '-' : item.schoolName}'), const SizedBox(height: 8), Text('Kelas: ${item.className.isEmpty ? '-' : item.className}'), const SizedBox(height: 8), Text('Paket: ${item.packageTitle}'), const SizedBox(height: 8), Text('Nominal: Rp${item.amount}')],),), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))])),
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