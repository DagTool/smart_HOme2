// lib/screens/join_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/device_provider.dart';
import '../widgets/widgets.dart';

class JoinHomeScreen extends StatefulWidget {
  const JoinHomeScreen({super.key});

  @override
  State<JoinHomeScreen> createState() => _JoinHomeScreenState();
}

class _JoinHomeScreenState extends State<JoinHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _homeNameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _displayCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    // Điền sẵn email làm tên hiển thị
    final email = context.read<AppAuthProvider>().user?.email ?? '';
    _displayCtrl.text = email.split('@').first;
  }

  @override
  void dispose() {
    _tab.dispose();
    _homeNameCtrl.dispose();
    _codeCtrl.dispose();
    _displayCtrl.dispose();
    super.dispose();
  }

  Future<void> _createHome() async {
    if (_homeNameCtrl.text.trim().isEmpty) return;

    setState(() => _loading = true);
    final homeProvider = context.read<HomeProvider>();

    try {
      final houseId = await homeProvider.createHome(
        _homeNameCtrl.text.trim(),
        _displayCtrl.text.trim(),
      );
      if (!mounted) return;

      context.read<DeviceProvider>().init(houseId);
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _joinHome() async {
    if (_codeCtrl.text.trim().isEmpty) return;

    setState(() => _loading = true);
    final homeProvider = context.read<HomeProvider>();

    final ok = await homeProvider.joinHome(
      _codeCtrl.text.trim().toUpperCase(),
      _displayCtrl.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      context.read<DeviceProvider>().init(homeProvider.houseId!);
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã mời không hợp lệ'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Thiết lập nhà'),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<AppAuthProvider>().signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text('Đăng xuất',
                style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chào mừng đến Smart Home 🏠',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ).animate().fadeIn(),
            const SizedBox(height: 8),
            const Text(
              'Tạo nhà mới hoặc tham gia nhà hiện có',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 24),

            // Tên hiển thị (chung cho cả 2 tab)
            AppTextField(
              controller: _displayCtrl,
              label: 'Tên hiển thị của bạn',
              prefixIcon: Icons.person_outline_rounded,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 20),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2235),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                dividerHeight: 0,
                tabs: const [
                  Tab(text: 'Tạo nhà mới'),
                  Tab(text: 'Nhập mã mời'),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 20),

            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  // Tab 1: Tạo nhà
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _homeNameCtrl,
                        label: 'Tên ngôi nhà',
                        hint: 'Ví dụ: Nhà tôi',
                        prefixIcon: Icons.home_rounded,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Tạo nhà',
                        loading: _loading,
                        onTap: _createHome,
                        icon: Icons.add_home_rounded,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF3B82F6).withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Color(0xFF3B82F6), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bạn sẽ trở thành admin và có thể mời thành viên khác vào nhà.',
                                style: TextStyle(
                                    color: Color(0xFF3B82F6), fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Tab 2: Nhập mã
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _codeCtrl,
                        label: 'Mã mời (8 ký tự)',
                        hint: 'Ví dụ: AB12CD34',
                        prefixIcon: Icons.vpn_key_rounded,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Tham gia',
                        loading: _loading,
                        onTap: _joinHome,
                        icon: Icons.login_rounded,
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
