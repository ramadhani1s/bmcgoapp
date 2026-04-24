import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/services/payment_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PaymentBniVaScreen extends StatefulWidget {
  const PaymentBniVaScreen({
    super.key,
    required this.packageId,
    required this.packageTitle,
    required this.finalAmount,
  });

  final int packageId;
  final String packageTitle;
  final int finalAmount;

  @override
  State<PaymentBniVaScreen> createState() => _PaymentBniVaScreenState();
}

class _PaymentBniVaScreenState extends State<PaymentBniVaScreen> {
  late DateTime _expiryTime;
  Timer? _countdownTimer;
  bool _isSubmittingTransfer = false;

  static const Color _headerOrange = Color(0xFFFF6D00);
  static const String _virtualAccountNumber = '8008267692142738';

  String _formatRupiah(int amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(amount).replaceAll(',', '.')}';
  }

  String _formatRemaining() {
    final diff = _expiryTime.difference(DateTime.now());
    if (diff.isNegative) {
      return '00:00:00';
    }

    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();
    _expiryTime = DateTime.now().add(const Duration(hours: 24));
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _copyValue(
    BuildContext context,
    String text,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label berhasil disalin')));
  }

  Future<void> _handleBack(BuildContext context) async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed('/payment');
  }

  Future<void> _submitTransferConfirmation() async {
    if (_isSubmittingTransfer) return;

    setState(() {
      _isSubmittingTransfer = true;
    });

    try {
      await PaymentService.submitManualTransfer(
        packageId: widget.packageId,
        packageTitle: widget.packageTitle,
        amount: widget.finalAmount,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi terkirim. Menunggu verifikasi admin.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingTransfer = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            decoration: const BoxDecoration(color: _headerOrange),
            child: SafeArea(
              bottom: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _handleBack(context),
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
                          'BNI Virtual Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Transfer ke nomor VA untuk menyelesaikan pembayaran',
                          style: TextStyle(
                            color: Color(0xFFFFE7D1),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFB300),
                      width: 1.3,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFFFFB300),
                        size: 17,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selesaikan pembayaran dalam',
                              style: TextStyle(
                                color: Color(0xFF7E7F86),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatRemaining(),
                              style: const TextStyle(
                                color: Color(0xFFFFB300),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _section(
                  title: '🪪 Nomor Virtual Account',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _headerOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BNI Virtual Account',
                          style: TextStyle(
                            color: Color(0xFFFFE7D1),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _virtualAccountNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _copyValue(
                              context,
                              _virtualAccountNumber,
                              'Nomor VA',
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('Salin Nomor VA'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  footer:
                      'Salin nomor VA dan lakukan pembayaran via ATM, Mobile Banking, atau Internet Banking BNI',
                ),
                const SizedBox(height: 14),
                _section(
                  title: '💰 Total Pembayaran',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paket: ${widget.packageTitle}',
                          style: const TextStyle(
                            color: Color(0xFF6A6E7E),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                color: Color(0xFF1F2232),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
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
                                    color: Color(0xFFFF6A6A),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _section(
                  title: '📋 Cara Pembayaran',
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📱 BNI Mobile Banking',
                        style: TextStyle(
                          color: Color(0xFF1F2232),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '1. Buka aplikasi BNI Mobile Banking\n'
                        '2. Pilih menu "Transfer"\n'
                        '3. Pilih "Virtual Account Billing"\n'
                        '4. Masukkan nomor VA: 8008267692142738\n'
                        '5. Masukkan nominal pembayaran\n'
                        '6. Konfirmasi dan selesaikan pembayaran',
                        style: TextStyle(
                          color: Color(0xFF666B7D),
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '🏧 ATM BNI',
                        style: TextStyle(
                          color: Color(0xFF1F2232),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '1. Masukkan kartu ATM dan PIN\n'
                        '2. Pilih menu "Menu Lainnya"\n'
                        '3. Pilih "Transfer"\n'
                        '4. Pilih "Rekening Tabungan"\n'
                        '5. Masukkan nomor VA: 8008267692142738\n'
                        '6. Masukkan nominal pembayaran\n'
                        '7. Konfirmasi dan selesaikan transaksi',
                        style: TextStyle(
                          color: Color(0xFF666B7D),
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFA726)),
                  ),
                  child: const Text(
                    '⚠ Penting!\n'
                    '• Transfer harus sesuai nominal yang tertera\n'
                    '• Pembayaran akan otomatis terverifikasi\n'
                    '• Nomor VA berlaku untuk 1x transaksi\n'
                    '• Jika melebihi batas waktu, transaksi akan dibatalkan',
                    style: TextStyle(
                      color: Color(0xFFEF6C00),
                      fontSize: 11.5,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmittingTransfer
                    ? null
                    : _submitTransferConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmittingTransfer
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Saya Sudah Transfer',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    String? footer,
  }) {
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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2C2E43),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
          if (footer != null) ...[
            const SizedBox(height: 8),
            Text(
              footer,
              style: const TextStyle(
                color: Color(0xFF9A9FAF),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
