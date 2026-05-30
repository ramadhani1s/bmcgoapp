import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/services/auth_service.dart';
import 'package:frontend_mobile_bmc/core/session/app_session.dart';
import 'package:frontend_mobile_bmc/widgets/auth/bmc_text_field.dart';
import 'package:frontend_mobile_bmc/widgets/auth/login_intro_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _primaryColor = Color(0xFFFF7070);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _pageBg = Color(0xFFF8F8F8);
  static const Color _labelColor = Color(0xFF25293B);

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
          .then((response) async {
            if (mounted) {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              setState(() {
                _isLoading = false;
              });

              final user = response['user'] as Map<String, dynamic>?;
              final token = response['token'] as String?;

              if (user != null) {
                await AppSession.saveAuthSession(
                  user: user,
                  token: token,
                  fallbackEmail: email,
                );

                navigator.pushReplacementNamed(
                  '/dashboard',
                  arguments: {'user': user, 'token': token},
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(response['message'] ?? 'Login berhasil'),
                    backgroundColor: Colors.green,
                  ),
                );
                navigator.pushReplacementNamed('/dashboard', arguments: {'user': {}});
              }
            }
          })
          .catchError((error) {
            if (mounted) {
              final messenger = ScaffoldMessenger.of(context);

              setState(() {
                _isLoading = false;
              });

              messenger.showSnackBar(
                SnackBar(
                  content: Text(error.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
    }
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
                            const LoginIntroCard(),
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
                                  BmcTextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    hint: 'Masukkan email Anda',
                                    icon: Icons.email_outlined,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Email tidak boleh kosong';
                                      }

                                      if (!value!.contains('@')) {
                                        return 'Email harus mengandung @';
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
                                  BmcTextField(
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    hint: 'Masukkan password Anda',
                                    icon: Icons.lock_outline,
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
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password tidak boleh kosong';
                                      }

                                      if (value.length < 8) {
                                        return 'Password minimal 8 karakter';
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
