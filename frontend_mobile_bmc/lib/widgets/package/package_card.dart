import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/services/paket_les_service.dart';

class PackageCard extends StatelessWidget {
  const PackageCard({
    super.key,
    required this.paket,
    required this.selected,
    required this.onSelect,
  });

  final Map<String, dynamic> paket;
  final bool selected;
  final ValueChanged<int> onSelect;

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

  @override
  Widget build(BuildContext context) {
    final id = _getInt(paket['id']);
    final title = _getString(paket['nama_paket']);
    
    final hargaAwal = _getInt(paket['harga_awal']);
    final diskon = _getInt(paket['diskon']);
    final finalPrice = _calculateFinalPrice(paket);
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
          color: selected ? const Color(0xFF2D4CC8) : const Color(0xFFE3E8FF),
          width: selected ? 1.6 : 1,
        ),
            boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => onSelect(id),
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
                              color: selected ? const Color(0xFF2D4CC8) : const Color(0xFFC9D2F3),
                              width: 2,
                            ),
                            color: selected ? const Color(0xFF2D4CC8) : Colors.white,
                          ),
                          child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
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
                if (_getString(paket['deskripsi']).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _getString(paket['deskripsi']),
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
                    children: const [
                      // Benefits are static for now; replace with dynamic data if available
                      Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 16, height: 16, child: Icon(Icons.check, size: 12, color: Colors.white)),
                            SizedBox(width: 8),
                            Expanded(child: Text('10 siswa per kelas', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ),
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
}
