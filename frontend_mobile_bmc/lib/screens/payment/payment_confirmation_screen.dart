import 'dart:async';

import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:frontend_mobile_bmc/models/payment_model.dart';
import 'package:frontend_mobile_bmc/core/session/app_session.dart';
import 'package:frontend_mobile_bmc/services/payment_service.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final int packageId;
  final String packageTitle;
  final String price;
  final String description;

  const PaymentConfirmationScreen({
    super.key,
    required this.packageId,
    required this.packageTitle,
    required this.price,
    required this.description,
  });

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  static const Color _blueHeader = Color(0xFF58B968);
  static const Color _accent = Color(0xFFFF7070);

  bool _isLoading = false;
  String? _errorMessage;
  String _statusMessage = 'Belum ada transaksi';
  MidtransSDK? _midtransSDK;
  String? _currentTransactionId;
  bool _isPollingStatus = false;
  bool _finalDialogShown = false;

  @override
  void initState() {
    super.initState();
    _initMidtrans();
  }

  // ✅ INIT MIDTRANS (FIXED)
  Future<void> _initMidtrans() async {
    try {
      _midtransSDK = await MidtransSDK.init(
        config: MidtransConfig(
          clientKey: "Mid-client-oGUyoloFZJXYlklg",
          merchantBaseUrl: "http://10.0.2.2:8081",
          colorTheme: ColorTheme(
            colorPrimary: _blueHeader,
            colorPrimaryDark: _blueHeader,
            colorSecondary: _accent,
          ),
        ),
      );
      _midtransSDK?.setTransactionFinishedCallback(_onTransactionFinished);
    } catch (e) {
      debugPrint("ERROR INIT MIDTRANS: $e");
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal inisialisasi Midtrans. Coba lagi.';
      });
    }
  }

  Future<Map<String, String>> _getUserData() async {
    String pickNonEmpty(List<String?> values, String fallback) {
      for (final value in values) {
        final text = value?.trim() ?? '';
        if (text.isNotEmpty) {
          return text;
        }
      }
      return fallback;
    }

    return {
      'name': pickNonEmpty([
        await AppSession.getUserName(),
      ], 'User'),
      'email': pickNonEmpty([
        await AppSession.getUserEmail(),
      ], 'user@example.com'),
      'phone': pickNonEmpty([
        await AppSession.getUserPhone(),
      ], '08123456789'),
    };
  }

  String _extractPrice() {
    return widget.price
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
  }

  // ✅ START PAYMENT (FIXED SAFE)
  Future<void> _startPayment() async {
    if (_midtransSDK == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Midtrans belum siap")));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = await _getUserData();

      final transactionRequest = TransactionRequest(
        packageId: widget.packageId.toString(),
        packageTitle: widget.packageTitle,
        amount: _extractPrice(),
        customerEmail: userData['email']!,
        customerName: userData['name']!,
        customerPhone: userData['phone']!,
      );

      final transactionResponse = await PaymentService.createTransaction(
        transactionRequest,
      );

      if (!mounted) return;
      _currentTransactionId = transactionResponse.transactionId;
      setState(() {
        _statusMessage = 'Transaksi dibuat. Memulai Midtrans...';
      });

      await _midtransSDK!.startPaymentUiFlow(token: transactionResponse.token);

      if (!mounted) return;
      await _startStatusPolling(transactionResponse.transactionId);

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Gagal membuat transaction'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ HANDLE RESULT (FIXED)
  Future<void> _onTransactionFinished(TransactionResult result) async {
    final transactionId = result.transactionId ?? _currentTransactionId;

    if (transactionId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Transaction ID tidak ditemukan.';
      });
      return;
    }

    final status = result.status.toLowerCase();

    if (!mounted) return;
    setState(() {
      _statusMessage = 'Midtrans: ${_humanStatus(status)}. Menyinkronkan status...';
      _isLoading = false;
    });

    await _startStatusPolling(transactionId);
  }

  Future<void> _startStatusPolling(String transactionId) async {
    if (_isPollingStatus) {
      return;
    }

    _isPollingStatus = true;
    try {
      for (var attempt = 0; attempt < 8 && mounted; attempt++) {
        final paymentStatus = await PaymentService.checkPaymentStatus(
          transactionId,
        );
        final status = paymentStatus.status.toLowerCase();

        if (status == 'success' || status == 'settlement' || status == 'capture') {
          await PaymentService.finishTransaction(transactionId, 'success');
          if (!mounted) return;
          setState(() {
            _statusMessage = 'Pembayaran berhasil. Status sudah diperbarui.';
            _isLoading = false;
          });
          if (!_finalDialogShown) {
            _finalDialogShown = true;
            _showSuccessDialog();
          }
          return;
        }

        if (status == 'failed' ||
            status == 'deny' ||
            status == 'cancel' ||
            status == 'canceled' ||
            status == 'expire') {
          await PaymentService.finishTransaction(transactionId, 'failed');
          if (!mounted) return;
          setState(() {
            _statusMessage = 'Pembayaran gagal atau dibatalkan.';
            _isLoading = false;
          });
          if (!_finalDialogShown) {
            _finalDialogShown = true;
            _showFailureDialog();
          }
          return;
        }

        if (!mounted) return;
        setState(() {
          _statusMessage = 'Status sekarang: ${paymentStatus.statusMessage.isNotEmpty ? paymentStatus.statusMessage : paymentStatus.status}';
        });

        await Future.delayed(const Duration(seconds: 2));
      }

      if (mounted) {
        setState(() {
          _statusMessage = 'Masih menunggu konfirmasi Midtrans.';
          _isLoading = false;
        });
      }
    } finally {
      _isPollingStatus = false;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Pembayaran Berhasil! 🎉'),
        content: const Text('Paket berhasil dibeli.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gagal ❌'),
        content: const Text('Pembayaran gagal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _midtransSDK?.removeTransactionFinishedCallback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int finalAmount = int.tryParse(_extractPrice()) ?? 0;
    final int normalAmount = finalAmount;
    final int discountAmount = (normalAmount - finalAmount).clamp(0, normalAmount);
    final String periodLabel = _periodLabel();
    final statusColor = _statusColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Pembayaran',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _blueHeader,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Container(
            alignment: Alignment.centerLeft,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: const Text(
              'Selesaikan pembayaran untuk aktivasi akun',
              style: TextStyle(color: Color(0xFFD9F5DB), fontSize: 12),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  children: [
                    _sectionCard(
                      title: 'Detail Paket',
                      icon: Icons.inventory_2_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.packageTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2A2A2A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            periodLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7A7A7A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFD5D5)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.local_offer, color: Color(0xFFF26D6D), size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'PROMO AKTIF',
                                  style: TextStyle(
                                    color: Color(0xFFF26D6D),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                _benefit('10 siswa per kelas'),
                                _benefit('Materi SNBT lengkap'),
                                _benefit('Try Out SNBT mingguan'),
                                _benefit('Drilling soal intensif'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _sectionCard(
                      title: 'Ringkasan Pembayaran',
                      icon: Icons.receipt_long_outlined,
                      child: Column(
                        children: [
                          _summaryRow('Harga Normal', _formatRupiah(normalAmount), muted: true),
                          const SizedBox(height: 6),
                          _summaryRow(
                            'Diskon Paket',
                            discountAmount > 0
                                ? '- ${_formatRupiah(discountAmount)}'
                                : '- Rp 0',
                            valueColor: const Color(0xFF22A447),
                          ),
                          const SizedBox(height: 6),
                          _summaryRow('Harga Setelah Diskon Paket', _formatRupiah(finalAmount), muted: true),
                          const Divider(height: 18),
                          _summaryRow(
                            'Total Pembayaran',
                            _formatRupiah(finalAmount),
                            valueColor: const Color(0xFFF26D6D),
                            bold: true,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDFF3E2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF84C98C)),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Total Hemat',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF2D8B3A)),
                                ),
                                Text(
                                  _formatRupiah(discountAmount),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2D8B3A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _sectionCard(
                      title: 'Status Pembayaran',
                      icon: Icons.info_outline,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              _statusMessage,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A3A3A),
                        ),
                      ),
                      Text(
                        _formatRupiah(finalAmount),
                        style: const TextStyle(
                          color: Color(0xFFF26D6D),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _startPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF26D6D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Bayar Sekarang',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _humanStatus(String status) {
    switch (status) {
      case 'success':
      case 'settlement':
      case 'capture':
        return 'berhasil';
      case 'pending':
        return 'pending';
      case 'cancel':
      case 'canceled':
        return 'dibatalkan';
      case 'deny':
      case 'expire':
      case 'failed':
        return 'gagal';
      default:
        return status;
    }
  }

  String _periodLabel() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month + 6, now.day);
    const months = [
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
      'Des',
    ];
    return '${months[now.month - 1]} ${now.year} - ${months[end.month - 1]} ${end.year}';
  }

  String _formatRupiah(int amount) {
    final formatter = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    return 'Rp ${amount.toString().replaceAllMapped(formatter, (m) => '${m.group(1)}.')}';
  }

  Color _statusColor() {
    final lower = _statusMessage.toLowerCase();
    if (lower.contains('berhasil')) {
      return const Color(0xFF2D8B3A);
    }
    if (lower.contains('gagal') || lower.contains('dibatalkan')) {
      return const Color(0xFFDC3C3C);
    }
    if (lower.contains('pending') || lower.contains('menunggu')) {
      return const Color(0xFFD58B00);
    }
    return const Color(0xFF456079);
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFF6A6A6A)),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 14, color: Color(0xFF57B868)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF3E3E3E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool muted = false,
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: muted ? const Color(0xFF8A8A8A) : const Color(0xFF434343),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: valueColor ?? (muted ? const Color(0xFF9A9A9A) : const Color(0xFF333333)),
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}