import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/alumni.dart';
import '../../services/auth_service.dart';

class AlumniProfileScreen extends StatelessWidget {
  const AlumniProfileScreen({super.key, required this.alumni});

  final Alumni alumni;

  @override
  Widget build(BuildContext context) {
    final photoUrl = _resolvePhotoUrl(alumni.foto);
    final initial = alumni.nama.isNotEmpty ? alumni.nama[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        titleSpacing: 0,
        title: const Text('Profil Alumni'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD6E4FF)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 760;
                        final avatar = Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE2E8F0),
                            border: Border.all(
                              color: const Color(0xFFBFDBFE),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: photoUrl != null
                                ? Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildFallbackAvatar(initial),
                                  )
                                : _buildFallbackAvatar(initial),
                          ),
                        );

                        final info = Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alumni.nama,
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 30,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                alumni.sekolah,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _badge(
                                    'Tahun Lulus ${alumni.tahunLulus}',
                                    const Color(0xFFE0F2FE),
                                    const Color(0xFF0369A1),
                                  ),
                                  _badge(
                                    'ID ${alumni.id}',
                                    const Color(0xFFF3F4F6),
                                    const Color(0xFF374151),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );

                        if (stacked) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              avatar,
                              const SizedBox(height: 16),
                              info,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [avatar, const SizedBox(width: 18), info],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 760;
                      final cards = [
                        _infoCard(
                          title: 'Data Utama',
                          items: [
                            _ProfileRow(
                              label: 'Nama Alumni',
                              value: alumni.nama,
                            ),
                            _ProfileRow(
                              label: 'Sekolah',
                              value: alumni.sekolah,
                            ),
                            _ProfileRow(
                              label: 'Tahun Lulus',
                              value: alumni.tahunLulus.toString(),
                            ),
                          ],
                        ),
                        _infoCard(
                          title: 'Catatan',
                          items: [
                            _ProfileRow(
                              label: 'Prestasi',
                              value:
                                  (alumni.prestasi == null ||
                                      alumni.prestasi!.trim().isEmpty)
                                  ? 'Belum ada catatan prestasi'
                                  : alumni.prestasi!.trim(),
                            ),
                            _ProfileRow(
                              label: 'Foto',
                              value: photoUrl == null
                                  ? 'Belum diupload'
                                  : 'Foto tersedia',
                            ),
                            _ProfileRow(
                              label: 'Status',
                              value: 'Tersimpan di data alumni',
                            ),
                          ],
                        ),
                      ];

                      if (stacked) {
                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 14),
                            cards[1],
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 14),
                          Expanded(child: cards[1]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan Profil',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          alumni.prestasi != null &&
                                  alumni.prestasi!.trim().isNotEmpty
                              ? alumni.prestasi!.trim()
                              : 'Belum ada deskripsi tambahan untuk alumni ini.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            height: 1.6,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                              ),
                              label: const Text('Kembali'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String initial) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _badge(String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoCard({required String title, required List<_ProfileRow> items}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          for (final item in items) ...[
            _detailRow(item.label, item.value),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF111827),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  String? _resolvePhotoUrl(String? foto) {
    final value = foto?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/uploads/')) {
      return '${AuthService.baseUrl}$value';
    }
    return '${AuthService.baseUrl}/uploads/$value';
  }
}

class _ProfileRow {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;
}
