import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/screens/payment/payment_confirmation_screen.dart';
import 'package:frontend_mobile_bmc/services/paket_les_service.dart';

class PackageScreen extends StatefulWidget {
  const PackageScreen({super.key});

  @override
  State<PackageScreen> createState() => _PackageScreenState();
}

class _PackageScreenState extends State<PackageScreen> {
  static const Color _blueHeader = Color(0xFF2D4CC8);
  static const Color _accent = Color(0xFFFF7070);
  static const Color _successGreen = Color(0xFF4CAF50);

  List<Map<String, dynamic>> _pakets = [];
  bool _isLoading = true;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _loadPakets();
  }

  Future<void> _loadPakets() async {
    setState(() => _isLoading = true);
    final pakets = await PaketLesService.getPaketLesList();

    // Filter only aktif pakets
    final aktivPakets = pakets.where((p) => p['status'] == 'aktif').toList();

    setState(() {
      _pakets = aktivPakets;
      _selectedId = aktivPakets.isNotEmpty ? aktivPakets.first['id'] : null;
      _isLoading = false;
    });
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  String _formatRupiah(int amount) {
    final formatter = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    return 'Rp ${amount.toString().replaceAllMapped(formatter, (match) => '${match.group(1)}.')}';
  }

  int _calculatePromoPrice(int hargaAwal, int diskon) {
    return (hargaAwal * (100 - diskon) / 100).toInt();
  }

  String _formatPeriod(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) return 'Sepanjang tahun';
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final months = [
        '',
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
      return '${start.day} ${months[start.month]} ${start.year} - ${end.day} ${months[end.month]} ${end.year}';
    } catch (e) {
      return 'Sepanjang tahun';
    }
  }

  List<String> _parseBenefits(String? deskripsi) {
    if (deskripsi == null || deskripsi.isEmpty) return [];
    // Split by line breaks or commas
    return deskripsi.split('\n').where((b) => b.trim().isNotEmpty).toList();
  }

  void _handleContinuePayment() {
    if (_selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Pilih paket terlebih dahulu"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedPaket =
        _pakets.firstWhere((p) => p['id'] == _selectedId, orElse: () => {});

    if (selectedPaket.isNotEmpty) {
      final hargaAwal = selectedPaket['harga_awal'] ?? 0;
      final diskon = selectedPaket['diskon'] ?? 0;
      final hargaPromo = _calculatePromoPrice(hargaAwal, diskon);
      final period = _formatPeriod(
        selectedPaket['tanggal_mulai_promo'],
        selectedPaket['tanggal_selesai_promo'],
      );
      final benefits = _parseBenefits(selectedPaket['deskripsi']);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentConfirmationScreen(
            packageId: selectedPaket['id'] ?? 0,
            packageTitle: selectedPaket['nama_paket'] ?? 'Paket',
            packagePeriod: period,
            benefits: benefits.isNotEmpty
                ? benefits
                : ['Akses ke semua materi pembelajaran'],
            normalAmount: hargaAwal,
            finalAmount: hargaPromo,
            promoTag: diskon > 0 ? 'PROMO ${diskon}%' : null,
            promoInfo: selectedPaket['tanggal_mulai_promo'] != null
                ? 'Berlaku ${_formatPeriod(selectedPaket['tanggal_mulai_promo'], selectedPaket['tanggal_selesai_promo'])}'
                : null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                color: _blueHeader,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _handleBack,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.18 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Paket Bimbel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pilih paket yang sesuai dengan kebutuhan',
                          style: TextStyle(
                            color: Color(0xFFD9E1FF),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/payment-history');
                    },
                    icon: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Riwayat Pembayaran',
                  ),
                ],
              ),
            ),

            // Paket List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: _blueHeader),
                          SizedBox(height: 16),
                          Text('Memuat paket...',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : _pakets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_rounded,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text(
                                'Belum ada paket yang tersedia',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Silakan hubungi admin untuk informasi paket',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPakets,
                          color: _blueHeader,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            itemCount: _pakets.length,
                            itemBuilder: (context, index) {
                              final paket = _pakets[index];
                              return _buildPaketCard(paket);
                            },
                          ),
                        ),
            ),

            // Button Lanjut Pembayaran
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleContinuePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Lanjut ke Konfirmasi Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildPaketCard(Map<String, dynamic> paket) {
    final isSelected = _selectedId == paket['id'];
    final hargaAwal = paket['harga_awal'] ?? 0;
    final diskon = paket['diskon'] ?? 0;
    final hargaPromo = _calculatePromoPrice(hargaAwal, diskon);
    final durasi = paket['durasi'] ?? 0;
    final tglMulai = paket['tanggal_mulai_promo'];
    final tglSelesai = paket['tanggal_selesai_promo'];

    // Format period display
    String periodDisplay = 'Sepanjang tahun';
    try {
      if (tglMulai != null && tglSelesai != null) {
        final start = DateTime.parse(tglMulai);
        final end = DateTime.parse(tglSelesai);
        periodDisplay = '${start.day} ${_getMonthName(start.month)} ${start.year} - ${end.day} ${_getMonthName(end.month)} ${end.year}';
      }
    } catch (e) {
      // ignore
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedId = paket['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _blueHeader : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.08 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan nama dan badges
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: diskon > 0
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFF0F4FF),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      paket['nama_paket'] ?? 'Paket',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (diskon > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-$diskon%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Period & Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tanggal & Durasi
                  Text(
                    periodDisplay,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '$durasi menit',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today_rounded,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '1 Semester',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Deskripsi
            if ((paket['deskripsi'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  paket['deskripsi'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),

            // Benefits checklist
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _successGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '10 sesi per kelas',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _successGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Materi lengkap semester 1',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _successGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Try Out bulanan',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _successGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Konsultasi dengan mentor',
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _successGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Akses materi digital',
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Harga section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Harga',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (diskon > 0)
                        Text(
                          _formatRupiah(hargaAwal),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _formatRupiah(diskon > 0 ? hargaPromo : hargaAwal),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: diskon > 0 ? _accent : _blueHeader,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Selection indicator
            if (isSelected)
              Container(
                width: double.infinity,
                height: 3,
                decoration: const BoxDecoration(
                  color: _blueHeader,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '',
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
    return months[month];
  }
}
