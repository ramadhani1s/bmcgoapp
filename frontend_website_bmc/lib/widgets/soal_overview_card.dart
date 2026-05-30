// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class SoalOverviewCard extends StatelessWidget {
  final String title;
  final String status; // 'Draft' atau 'Dipublikasikan'
  final DateTime? tanggal;
  final int durasiMenit;
  final int soalTerbuat;
  final int totalSoal;
  final Map<String, int> kategoriProgress; // Contoh: {'PU': 0, 'PPU': 20, ...}
  final VoidCallback onKelolaSoal;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Color primaryColor;

  const SoalOverviewCard({
    Key? key,
    required this.title,
    required this.status,
    this.tanggal,
    required this.durasiMenit,
    required this.soalTerbuat,
    required this.totalSoal,
    required this.kategoriProgress,
    required this.onKelolaSoal,
    this.onEdit,
    this.onDelete,
    this.primaryColor = AppColors.accentBlue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressPercent = totalSoal > 0
        ? (soalTerbuat / totalSoal * 100).toInt()
        : 0;
    final isPublished = status.toLowerCase().contains('publish');
    final tanggalStr = tanggal != null
        ? '${tanggal!.day} ${_getMonthName(tanggal!.month)} ${tanggal!.year}'
        : '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan title dan status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPublished
                        ? const Color(0xFFDCFCE7)
                        : AppColors.blueLightBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPublished
                          ? const Color(0xFF065F46)
                          : AppColors.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Info row: tanggal, durasi, soal count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(Icons.calendar_today_outlined, tanggalStr),
                _buildInfoItem(Icons.timer_outlined, '$durasiMenit menit'),
                _buildInfoItem(
                  Icons.assignment_outlined,
                  '$soalTerbuat/$totalSoal soal',
                ),
              ],
            ),
          ),

          // Progress section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progress Soal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    Text(
                      '$progressPercent%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalSoal > 0 ? soalTerbuat / totalSoal : 0,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action buttons: primary action + centered square edit/delete icons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: onKelolaSoal,
                      icon: const Icon(Icons.menu_book_outlined, size: 18),
                      label: const Text('Kelola Soal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildActionIconButton(
                  icon: Icons.edit_outlined,
                  iconColor: const Color(0xFF6B7280),
                  borderColor: const Color(0xFFE5E7EB),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                const SizedBox(width: 8),
                _buildActionIconButton(
                  icon: Icons.delete_outline,
                  iconColor: const Color(0xFFEF4444),
                  borderColor: const Color(0xFFFECACA),
                  onPressed: onDelete,
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(child: Icon(icon, size: 18, color: iconColor)),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
