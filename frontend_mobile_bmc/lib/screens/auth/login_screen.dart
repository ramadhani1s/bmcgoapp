import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _primaryColor = Color(0xFFFF7070);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _pageBg = Color(0xFFF8F8F8);
  static const Color _fieldBg = Color(0xFFF4F5FA);
  static const Color _labelColor = Color(0xFF25293B);
  static const Color _hintColor = Color(0xFF9B9FB0);
  static const Color _pillBg = Color(0xFFEDEDED);
  static const Color _pillText = Color(0xFF555555);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String email = _emailController.text;
      String password = _passwordController.text;

      AuthService.login(email, password)
          .then((response) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });

              final user = response['user'] as Map<String, dynamic>?;
              final token = response['token'] as String?;

              if (user != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selamat datang, ${user['nama']}!'),
                    backgroundColor: Colors.green,
                  ),
                );

                Navigator.of(context).pushReplacementNamed(
                  '/dashboard',
                  arguments: {'user': user, 'token': token},
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(response['message'] ?? 'Login berhasil'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(
                  context,
                ).pushReplacementNamed('/dashboard', arguments: {'user': {}});
              }
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
    }
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _hintColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8DBE4), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC6CAD5), width: 1.1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      filled: true,
      fillColor: _fieldBg,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 390),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 92,
                                height: 92,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F0E5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Image.asset(
                                  'assets/images/bmc_logo.jpeg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Selamat Datang!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _labelColor,
                                fontSize: 31,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Silahkan masuk ke akun Anda',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF9AA0AE),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _pillBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'BINTANG MUDA CENTER',
                                  style: TextStyle(
                                    color: _pillText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 34),
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                18,
                                16,
                                16,
                              ),
                              decoration: BoxDecoration(
                                color: _cardBg,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.07),
                                    blurRadius: 24,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Email',
                                    style: TextStyle(
                                      color: _labelColor,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _inputDecoration(
                                      hint: 'Masukkan email Anda',
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Email tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Password',
                                    style: TextStyle(
                                      color: _labelColor,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    decoration: _inputDecoration(
                                      hint: 'Masukkan email Anda',
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: const Color(0xFFA0A5B2),
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible =
                                                !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Password tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    height: 46,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primaryColor,
                                        disabledBackgroundColor: _primaryColor,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.login_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Masuk',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Belum punya akun? ',
                                        style: TextStyle(
                                          color: Color(0xFF9A9EAC),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(
                                            context,
                                          ).pushReplacementNamed('/register');
                                        },
                                        child: const Text(
                                          'Daftar sekarang',
                                          style: TextStyle(
                                            color: _primaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
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
              ),
            );
          },
        ),
      ),
    );
  }
}
