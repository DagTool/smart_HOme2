// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AppAuthProvider>();
    final ok = await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Đăng nhập thất bại'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
    // Nếu ok, AppRouter sẽ tự điều hướng
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo
              Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.home_rounded,
                      color: Color(0xFF3B82F6), size: 36),
                ),
              ).animate().fadeIn().slideY(begin: -0.2),
              const SizedBox(height: 32),
              const Text(
                'Chào mừng!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 6),
              const Text(
                'Đăng nhập để điều khiển ngôi nhà của bạn',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 40),

              // Email
              AppTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),

              // Password
              AppTextField(
                controller: _passCtrl,
                label: 'Mật khẩu',
                hint: '••••••••',
                obscure: !_showPass,
                prefixIcon: Icons.lock_outline_rounded,
                suffix: GestureDetector(
                  onTap: () => setState(() => _showPass = !_showPass),
                  child: Icon(
                    _showPass ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38,
                    size: 18,
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 28),

              PrimaryButton(
                label: 'Đăng nhập',
                loading: auth.loading,
                onTap: _login,
                icon: Icons.login_rounded,
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, '/register'),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Chưa có tài khoản? ',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Đăng ký',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
