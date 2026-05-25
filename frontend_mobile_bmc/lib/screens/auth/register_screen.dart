import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/services/auth_service.dart';
import 'package:frontend_mobile_bmc/widgets/auth/bmc_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _kelasController = TextEditingController();
  final _sekolahController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _alamatController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed('/entry');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kelasController.dispose();
    _sekolahController.dispose();
    _whatsappController.dispose();
    _alamatController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.register(
        _namaController.text.trim(),
        _kelasController.text.trim(),
        _sekolahController.text.trim(),
        _whatsappController.text.trim(),
        _alamatController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Registrasi berhasil'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF87171),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: _handleBack,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.18 * 255).round()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Registrasi Siswa Baru',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Data Siswa',
                    style: TextStyle(
                      color: Color(0xFFFFE0E0),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      BmcTextField(
                        controller: _namaController,
                        hint: 'Nama Lengkap Siswa *',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Nama lengkap wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      BmcTextField(
                        controller: _kelasController,
                        hint: 'Kelas *',
                        icon: Icons.class_outlined,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Kelas wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      BmcTextField(
                        controller: _sekolahController,
                        hint: 'Asal Sekolah *',
                        icon: Icons.school_outlined,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Asal sekolah wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      BmcTextField(
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        hint: 'No. WhatsApp Siswa *',
                        icon: Icons.phone_android_outlined,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Nomor WhatsApp wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      BmcTextField(
                        controller: _alamatController,
                        minLines: 2,
                        maxLines: 4,
                        hint: 'Alamat Lengkap Siswa *',
                        icon: Icons.location_on_outlined,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Alamat lengkap wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      BmcTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        hint: 'Email *',
                        icon: Icons.email_outlined,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Email wajib diisi';
                          }
                          if (!value!.contains('@')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      BmcTextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        hint: 'Password *',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Password wajib diisi';
                          }
                          if (value!.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE11D48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Lanjut',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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
