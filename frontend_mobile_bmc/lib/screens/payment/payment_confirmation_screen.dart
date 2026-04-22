import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:frontend_mobile_bmc/screens/payment/payment_bni_va_screen.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final int packageId;
  final String packageTitle;
  final String packagePeriod;
  final List<String> benefits;
  final int normalAmount;
  final int finalAmount;
  final String? promoTag;
  final String? promoInfo;

  const PaymentConfirmationScreen({
    super.key,
    required this.packageId,
    required this.packageTitle,
    required this.packagePeriod,
    required this.benefits,
    required this.normalAmount,
    required this.finalAmount,
    this.promoTag,
    this.promoInfo,
  });

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  static const Color _headerGreen = Color(0xFF4CAF50);
  static const Color _accent = Color(0xFFFF6A6A);

  String _formatRupiah(int amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(amount).replaceAll(',', '.')}';
  }

  Future<void> _handleBack() async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed('/package');
  }

  void _continuePayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentBniVaScreen(
          packageTitle: widget.packageTitle,
          finalAmount: widget.finalAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discount = widget.normalAmount > widget.finalAmount
        ? widget.normalAmount - widget.finalAmount
        : 0;
    final hasPromo = discount > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            decoration: const BoxDecoration(color: _headerGreen),
            child: SafeArea(
              bottom: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _handleBack,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
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
                          'Konfirmasi Pembayaran',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Selesaikan pembayaran untuk aktivasi akun',
                          style: TextStyle(
                            color: Color(0xFFE6F8E9),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 180),
              children: [
                _buildPackageDetailCard(),
                const SizedBox(height: 14),
                _buildSummaryCard(hasPromo: hasPromo, discount: discount),
                const SizedBox(height: 14),
                _buildMethodCard(),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: const Color(0xFFF5F6F8),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEFF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          color: Color(0xFF2C2E43),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _formatRupiah(widget.finalAmount),
                            style: const TextStyle(
                              color: _accent,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _continuePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Bayar Sekarang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageDetailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Paket',
            style: TextStyle(
              color: Color(0xFF2C2E43),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.packageTitle,
            style: const TextStyle(
              color: Color(0xFF1F2232),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.packagePeriod,
            style: const TextStyle(color: Color(0xFF8A8FA1), fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (widget.promoTag != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFC8C8)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6A6A),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.promoTag!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.promoInfo ?? '-',
                      style: const TextStyle(
                        color: Color(0xFF878A95),
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: List.generate(widget.benefits.length, (index) {
                final benefit = widget.benefits[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == widget.benefits.length - 1 ? 0 : 7,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.check_circle,
                          color: Color(0xFF4CAF50),
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          benefit,
                          style: const TextStyle(
                            color: Color(0xFF5F6478),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required bool hasPromo, required int discount}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pembayaran',
            style: TextStyle(
              color: Color(0xFF2C2E43),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _priceRow(
                  'Harga Normal',
                  _formatRupiah(widget.normalAmount),
                  trailingStyle: TextStyle(
                    color: hasPromo ? const Color(0xFFADB2BE) : _accent,
                    fontSize: 12,
                    decoration: hasPromo
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    fontWeight: hasPromo ? FontWeight.w500 : FontWeight.w800,
                  ),
                ),
                if (hasPromo) const SizedBox(height: 7),
                if (hasPromo)
                  _priceRow(
                    'Diskon Paket (${widget.promoTag ?? 'PROMO'})',
                    '- ${_formatRupiah(discount)}',
                    trailingStyle: const TextStyle(
                      color: Color(0xFF2F9E44),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (hasPromo) const SizedBox(height: 7),
                if (hasPromo)
                  _priceRow(
                    'Harga Setelah Diskon Paket',
                    _formatRupiah(widget.finalAmount),
                  ),
                const SizedBox(height: 9),
                const Divider(color: Color(0xFFD6D9E3), height: 1),
                const SizedBox(height: 9),
                _priceRow(
                  'Total Pembayaran',
                  _formatRupiah(widget.finalAmount),
                  titleStyle: const TextStyle(
                    color: Color(0xFF24273A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  trailingStyle: const TextStyle(
                    color: _accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (hasPromo) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4EA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF57C26A)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Hemat',
                    style: TextStyle(color: Color(0xFF4E9C59), fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatRupiah(discount),
                    style: const TextStyle(
                      color: Color(0xFF2F9E44),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _priceRow(
    String title,
    String value, {
    TextStyle? titleStyle,
    TextStyle? trailingStyle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style:
                titleStyle ??
                const TextStyle(color: Color(0xFF646A7D), fontSize: 12),
          ),
        ),
        Text(
          value,
          style:
              trailingStyle ??
              const TextStyle(
                color: Color(0xFF5E6378),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildMethodCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Metode Pembayaran',
            style: TextStyle(
              color: Color(0xFF2C2E43),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F3FE),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFF1E88E5), width: 1.3),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'BNI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BNI Virtual Account',
                        style: TextStyle(
                          color: Color(0xFF1F2232),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Transfer via VA BNI',
                        style: TextStyle(
                          color: Color(0xFF8B90A1),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E88E5),
                    border: Border.all(color: const Color(0xFF1E88E5)),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
