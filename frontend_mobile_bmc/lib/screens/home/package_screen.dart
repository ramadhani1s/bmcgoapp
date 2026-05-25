import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/screens/payment/payment_confirmation_screen.dart';
import 'package:frontend_mobile_bmc/screens/payment/payment_history_screen.dart';
import 'package:frontend_mobile_bmc/services/paket_les_service.dart';
import 'package:frontend_mobile_bmc/widgets/package/package_header.dart';
import 'package:frontend_mobile_bmc/widgets/package/package_card.dart';

class PackageScreen extends StatefulWidget {
  const PackageScreen({super.key});

  @override
  State<PackageScreen> createState() => _PackageScreenState();
}

class _PackageScreenState extends State<PackageScreen> {
  static const Color _headerBlue = Color(0xFF2D4CC8);
  static const Color _bg = Color(0xFFF5F7FF);

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _packages = const [];
  int? _selectedPackageId;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allPackages = await PaketLesService.getPaketLesList();
      final visiblePackages = allPackages.where(_isVisibleForStudent).toList();

      if (!mounted) return;
      setState(() {
        _packages = visiblePackages;
        _selectedPackageId ??= visiblePackages.isNotEmpty
            ? _getInt(visiblePackages.first['id'])
            : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _isVisibleForStudent(Map<String, dynamic> paket) {
    final status = _getString(paket['status']).toLowerCase().trim();
    if (status.isEmpty) return true;
    return status == 'aktif' || status == 'active' || status == 'published';
  }

  int _getInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _getString(dynamic value) => value?.toString() ?? '';

  int _calculateFinalPrice(Map<String, dynamic> paket) {
    final hargaAwal = _getInt(paket['harga_awal']);
    final diskon = _getInt(paket['diskon']);
    if (hargaAwal <= 0) return 0;
    if (diskon <= 0) return hargaAwal;
    return PaketLesService.calculateHargaPromo(hargaAwal, diskon);
  }


  // semester formatting moved to PackageCard widget


  Map<String, dynamic>? _selectedPackageData() {
    if (_selectedPackageId == null) return null;
    for (final paket in _packages) {
      if (_getInt(paket['id']) == _selectedPackageId) return paket;
    }
    return null;
  }

  Future<void> _openCheckout() async {
    final paket = _selectedPackageData();
    if (paket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih paket terlebih dahulu.')),
      );
      return;
    }

    final hargaFinal = _calculateFinalPrice(paket);
    final title = _getString(paket['nama_paket']);
    final description = _getString(paket['deskripsi']);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmationScreen(
          packageId: _getInt(paket['id']),
          packageTitle: title,
          price: PaketLesService.formatRupiah(hargaFinal),
          description: description,
        ),
      ),
    );
  }

  Widget _buildAppBarAction() {
    return IconButton(
      tooltip: 'Status pembayaran',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PaymentHistoryScreen(),
          ),
        );
      },
      icon: const Icon(Icons.receipt_long_outlined),
    );
  }

  // Header moved to PackageHeader widget; helper removed.

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage ?? 'Gagal memuat paket.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadPackages,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: Colors.blueGrey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Belum ada paket aktif dari admin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Begitu admin menambah paket les baru, paket ini akan tampil otomatis di sini.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadPackages,
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      ),
    );
  }

  // Package helpers moved into PackageCard widget; removed unused helpers.

  // Package card UI moved to PackageCard widget; helper removed.


  @override
  Widget build(BuildContext context) {
    final selectedPackage = _selectedPackageData();
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _headerBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pilih Paket Bimbel'),
        actions: [_buildAppBarAction()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const PackageHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadPackages,
                child: _isLoading
                    ? _buildLoading()
                    : (_errorMessage != null
                        ? _buildError()
                        : _packages.isEmpty
                            ? _buildEmpty()
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                                children: [
                                  ..._packages.map((p) => PackageCard(
                                        paket: p,
                                        selected: _selectedPackageId != null && _getInt(p['id']) == _selectedPackageId,
                                        onSelect: (id) => setState(() => _selectedPackageId = id),
                                      )),
                                  const SizedBox(height: 86),
                                ],
                              )),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: selectedPackage == null ? null : _openCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              selectedPackage == null ? 'Pilih Paket Dulu' : 'Lanjut ke Konfirmasi Pembayaran',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}