import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/screens/payment/payment_confirmation_screen.dart';

class PackageScreen extends StatefulWidget {
  const PackageScreen({super.key});

  @override
  State<PackageScreen> createState() => _PackageScreenState();
}

class _PackageScreenState extends State<PackageScreen> {
  static const Color _blueHeader = Color(0xFF2D4CC8);
  static const Color _accent = Color(0xFFFF7070);

  final List<_PackageOption> _packages = const [
    _PackageOption(
      id: 1,
      title: 'Kelas 10 SMA - 1 Semester',
      period: 'Jan 2026 - Juli 2026',
      students: '10 siswa/kelas',
      duration: '1 Semester',
      description: 'Paket bimbel reguler untuk kelas 10 SMA semester 1',
      benefits: [
        '10 siswa per kelas',
        'Materi lengkap semester 1',
        'Try Out bulanan',
        'Konsultasi dengan mentor',
        'Akses materi digital',
      ],
      priceLabel: 'Total Biaya',
      price: 'Rp 4.250.000',
    ),
    _PackageOption(
      id: 2,
      title: 'Kelas 10 SMA - 3 Semester',
      period: 'Jan 2026 - Juli 2027',
      students: '10 siswa/kelas',
      duration: '3 Semester',
      description: 'Paket bimbel 3 semester untuk kelas 10 SMA dengan diskon',
      benefits: [
        '10 siswa per kelas',
        'Materi lengkap 3 semester',
        'Try Out bulanan',
        'Konsultasi dengan mentor',
        'Akses materi digital',
      ],
      normalPrice: 'Rp 13.500.000',
      promoPrice: 'Rp 12.750.000',
      promoTag: 'PROMO 5%',
      promoInfo: 'Promo berlaku 01 Jan - 31 Des 2025',
      savingsInfo: 'Hemat Rp 750.000',
    ),
    _PackageOption(
      id: 3,
      title: 'Kelas 11 SMA - 1 Semester',
      period: 'Jan 2026 - Juli 2026',
      students: '10 siswa/kelas',
      duration: '1 Semester',
      description: 'Paket bimbel reguler untuk kelas 11 SMA semester 1',
      benefits: [
        '10 siswa per kelas',
        'Materi lengkap semester 1',
        'Try Out bulanan',
        'Konsultasi dengan mentor',
        'Akses materi digital',
      ],
      priceLabel: 'Total Biaya',
      price: 'Rp 5.000.000',
    ),
    _PackageOption(
      id: 4,
      title: 'Kelas 12 SMA + Super Intensive 2026',
      period: 'Jan 2026 - September 2026',
      students: '10 siswa/kelas',
      duration: 'Jan - September 2026',
      description: 'Paket super intensif persiapan SNBT untuk kelas 12',
      benefits: [
        '10 siswa per kelas',
        'Materi SNBT lengkap',
        'Try Out SNBT mingguan',
        'Drilling soal intensif',
        'Konsultasi strategi ujian',
        'Akses materi digital premium',
      ],
      normalPrice: 'Rp 8.000.000',
      promoPrice: 'Rp 6.000.000',
      promoTag: 'PROMO 25%',
      promoInfo: 'Promo berlaku 01 Jan - 31 Mar 2026',
      savingsInfo: 'Hemat Rp 2.000.000',
      isRecommended: true,
    ),
  ];

  int _selectedId = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
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
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
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
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                itemCount: _packages.length,
                itemBuilder: (context, index) {
                  final item = _packages[index];
                  final isSelected = item.id == _selectedId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PackageCard(
                      item: item,
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedId = item.id;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: const Color(0xFFF6F6F8),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              final selected = _packages.firstWhere((e) => e.id == _selectedId);
              // Extract numeric price
              final priceStr = selected.promoPrice ?? selected.price ?? 'Rp 0';

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentConfirmationScreen(
                    packageId: selected.id,
                    packageTitle: selected.title,
                    price: priceStr,
                    description: selected.description,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text(
              'Lanjut ke Konfirmasi Pembayaran',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _PackageOption item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? const Color(0xFFFF7F7F) : Colors.transparent,
            width: 1.1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: Color(0xFF25273D),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selected
                            ? const Color(0xFFFF7070)
                            : const Color(0xFFD5D5D5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.period,
                    style: const TextStyle(
                      color: Color(0xFF9194A7),
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 14,
                        color: Color(0xFF9A9EB0),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.students,
                        style: const TextStyle(
                          color: Color(0xFF7E8293),
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: Color(0xFF9A9EB0),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.duration,
                        style: const TextStyle(
                          color: Color(0xFF7E8293),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: Color(0xFF737889),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: item.benefits
                          .map(
                            (benefit) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 15,
                                    color: Color(0xFF4CAF50),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      benefit,
                                      style: const TextStyle(
                                        color: Color(0xFF6A6F81),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (item.promoInfo != null && item.savingsInfo != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFFFF5A5A),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.promoInfo!,
                              style: const TextStyle(
                                color: Color(0xFFFF5A5A),
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.savingsInfo!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (item.promoPrice != null)
                    Row(
                      children: [
                        const Text(
                          'Harga Normal',
                          style: TextStyle(
                            color: Color(0xFFA1A4B0),
                            fontSize: 11.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.normalPrice!,
                          style: const TextStyle(
                            color: Color(0xFFB3B5BE),
                            fontSize: 11.5,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  if (item.promoPrice != null) const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        item.promoPrice == null
                            ? item.priceLabel!
                            : 'Harga Promo',
                        style: TextStyle(
                          color: item.promoPrice == null
                              ? const Color(0xFF9CA0AE)
                              : const Color(0xFF4CAF50),
                          fontSize: 11.5,
                          fontWeight: item.promoPrice == null
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.promoPrice ?? item.price!,
                        style: const TextStyle(
                          color: Color(0xFFFF7070),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (item.promoTag != null)
              Positioned(
                top: -1,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.promoTag!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (item.isRecommended)
              Positioned(
                top: -1,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC928),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'REKOMENDASI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PackageOption {
  const _PackageOption({
    required this.id,
    required this.title,
    required this.period,
    required this.students,
    required this.duration,
    required this.description,
    required this.benefits,
    this.priceLabel,
    this.price,
    this.normalPrice,
    this.promoPrice,
    this.promoTag,
    this.promoInfo,
    this.savingsInfo,
    this.isRecommended = false,
  });

  final int id;
  final String title;
  final String period;
  final String students;
  final String duration;
  final String description;
  final List<String> benefits;
  final String? priceLabel;
  final String? price;
  final String? normalPrice;
  final String? promoPrice;
  final String? promoTag;
  final String? promoInfo;
  final String? savingsInfo;
  final bool isRecommended;
}
