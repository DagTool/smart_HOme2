// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu xác nhận không khớp'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final auth = context.read<AppAuthProvider>();
    final ok = await auth.register(
        _emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Đăng ký thất bại'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tạo tài khoản',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700),
              ).animate().fadeIn(),
              const SizedBox(height: 6),
              const Text(
                'Đăng ký để bắt đầu sử dụng Smart Home',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 36),

              AppTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),

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
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),

              AppTextField(
                controller: _confirmCtrl,
                label: 'Xác nhận mật khẩu',
                hint: '••••••••',
                obscure: true,
                prefixIcon: Icons.lock_outline_rounded,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 28),

              PrimaryButton(
                label: 'Đăng ký',
                loading: auth.loading,
                onTap: _register,
                icon: Icons.person_add_rounded,
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
