import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/screens/payment/payment_confirmation_screen.dart';
import 'package:frontend_mobile_bmc/screens/payment/payment_history_screen.dart';
import 'package:frontend_mobile_bmc/services/paket_les_service.dart';

class PackageScreen extends StatefulWidget {
  const PackageScreen({super.key});

  @override
  State<PackageScreen> createState() => _PackageScreenState();
}

class _PackageScreenState extends State<PackageScreen> {
  static const Color _headerBlue = Color(0xFF2D4CC8);
  static const Color _bg = Color(0xFFF5F7FF);
  static const Color _cardBorder = Color(0xFFE3E8FF);

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

  bool _hasPromo(Map<String, dynamic> paket) {
    final diskon = _getInt(paket['diskon']);
    return diskon > 0;
  }

  String _formatSemester(Map<String, dynamic> paket) {
    final durasi = _getInt(paket['durasi']);
    if (durasi <= 0) return 'Durasi tidak tersedia';
    return durasi == 1 ? '1 Semester' : '$durasi Semester';
  }

  String _formatPromoRange(Map<String, dynamic> paket) {
    DateTime? parseDate(dynamic value) {
      final raw = value?.toString();
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    final start = parseDate(paket['tanggal_mulai_promo']);
    final end = parseDate(paket['tanggal_selesai_promo']);
    if (start == null && end == null) {
      return _formatSemester(paket);
    }

    String formatShort(DateTime date) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${months[date.month - 1]} ${date.year}';
    }

    if (start != null && end != null) {
      return '${formatShort(start)} - ${formatShort(end)}';
    }
    if (start != null) return 'Mulai ${formatShort(start)}';
    return 'Sampai ${formatShort(end!)}';
  }

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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_headerBlue, Color(0xFF2440B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Pilih Paket Bimbel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Pilih paket yang sesuai dengan kebutuhan',
            style: TextStyle(
              color: Color(0xFFDCE5FF),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> paket) {
    final id = _getInt(paket['id']);
    final title = _getString(paket['nama_paket']);
    final description = _getString(paket['deskripsi']);
    final hargaAwal = _getInt(paket['harga_awal']);
    final diskon = _getInt(paket['diskon']);
    final finalPrice = _calculateFinalPrice(paket);
    final selected = id == _selectedPackageId;
    final hasPromo = _hasPromo(paket);
    final promoTag = hasPromo ? 'PROMO $diskon%' : 'Paket Aktif';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? _headerBlue : _cardBorder,
          width: selected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => setState(() => _selectedPackageId = id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isEmpty ? 'Paket Tanpa Nama' : title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF172033),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatPromoRange(paket),
                            style: TextStyle(
                              color: Colors.blueGrey.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? _headerBlue : const Color(0xFFC9D2F3),
                              width: 2,
                            ),
                            color: selected ? _headerBlue : Colors.white,
                          ),
                          child: selected
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 15, color: Colors.blueGrey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      '10 siswa/kelas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule_outlined, size: 15, color: Colors.blueGrey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      _formatSemester(paket),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.blueGrey.shade600,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBenefitRow('10 siswa per kelas'),
                      _buildBenefitRow('Materi lengkap semester 1'),
                      _buildBenefitRow('Try out bulanan'),
                      _buildBenefitRow('Konsultasi dengan mentor'),
                      _buildBenefitRow('Akses materi digital'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Harga',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (hasPromo && hargaAwal > finalPrice) ...[
                          Text(
                            PaketLesService.formatRupiah(hargaAwal),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey.shade400,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.blueGrey.shade400,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          PaketLesService.formatRupiah(finalPrice),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF5C5C),
                          ),
                        ),
                      ],
                    ),
                    if (hasPromo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          promoTag,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAFBF0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          promoTag,
                          style: const TextStyle(
                            color: Color(0xFF16A34A),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
            _buildHeader(),
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
                                  ..._packages.map(_buildPackageCard),
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