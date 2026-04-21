import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:frontend_mobile_bmc/models/payment_model.dart';
import 'package:frontend_mobile_bmc/services/payment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const Color _blueHeader = Color(0xFF2D4CC8);
  static const Color _accent = Color(0xFFFF7070);

  bool _isLoading = false;
  String? _errorMessage;
  MidtransSDK? _midtransSDK;
  String? _currentTransactionId;

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
          merchantBaseUrl: "http://10.0.2.2:8080", // ✅ FIX localhost
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
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('user_name') ?? 'User',
      'email': prefs.getString('user_email') ?? 'user@example.com',
      'phone': prefs.getString('user_phone') ?? '08xxxxxxxxxx',
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

      await _midtransSDK!.startPaymentUiFlow(token: transactionResponse.token);

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

    if (status == 'success' || status == 'settlement' || status == 'capture') {
      await PaymentService.finishTransaction(transactionId, 'success');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccessDialog();
      return;
    }

    if (status == 'pending') {
      await PaymentService.finishTransaction(transactionId, 'pending');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showPendingDialog();
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    _showFailureDialog();
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

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Menunggu Pembayaran ⏳'),
        content: const Text('Silahkan selesaikan pembayaran VA BNI Anda.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
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
    final priceAmount = _extractPrice();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Pembayaran'),
        backgroundColor: _blueHeader,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _startPayment,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Bayar Rp $priceAmount"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
