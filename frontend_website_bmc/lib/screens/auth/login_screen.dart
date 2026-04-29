import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final user = result['user'] as User;

      print(
        'DEBUG: Login user - ID: ${user.id}, Role: ${user.roleId}, Nama: ${user.nama}',
      );
      print(
        'DEBUG: isAdmin=${user.isAdmin}, isMentor=${user.isMentor}, isSiswa=${user.isSiswa}',
      );

      if (user.isAdmin) {
        Navigator.of(context).pushReplacementNamed('/admin-dashboard');
      } else if (user.isMentor) {
        Navigator.of(context).pushReplacementNamed('/mentor-dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Role tidak didukung (ID: ${user.roleId}). Hubungi admin.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        await AuthService.logout();
        return;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(
        color: Color(0xFF6B7280),
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Masuk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildBrandPanel({bool compact = false}) {
    return Container(
      color: const Color(0xFFEFF1F6),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/BMC .png',
                width: compact ? 88 : 170,
                height: compact ? 88 : 170,
                fit: BoxFit.contain,
              ),
              SizedBox(height: compact ? 12 : 24),
              Text(
                'Portal Admin & Mentor\nBintang Muda Center',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 26 : 50,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                  height: 1.18,
                ),
              ),
              SizedBox(height: compact ? 8 : 24),
              Text(
                'Selamat datang di sistem manajemen Bimbingan Belajar\nBintang Muda Center. Kelola semua aspek operasional\ndengan mudah.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 12 : 14,
                  color: Color(0xFF4B5563),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginFormCard({bool compact = false}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 420 : 560),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masuk ke Portal',
              style: TextStyle(
                fontSize: compact ? 28 : 52,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: compact ? 18 : 34),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration('Email', Icons.mail_outline),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email tidak boleh kosong';
                }
                return null;
              },
            ),
            SizedBox(height: compact ? 14 : 18),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: _inputDecoration('Password', Icons.lock_outline)
                  .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF9CA3AF),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password tidak boleh kosong';
                }
                return null;
              },
            ),
            SizedBox(height: compact ? 18 : 22),
            _buildLoginButton(),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Text(
                'Gunakan akun admin atau akun mentor yang sudah dibuat dari menu manajemen mentor.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isDesktop
          ? Row(
              children: [
                Expanded(flex: 44, child: _buildBrandPanel()),
                Expanded(
                  flex: 56,
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 52,
                          vertical: 34,
                        ),
                        child: _buildLoginFormCard(),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    SizedBox(
                      height: 240,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF1F6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildBrandPanel(compact: true),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLoginFormCard(compact: true),
                  ],
                ),
              ),
            ),
    );
  }
}
