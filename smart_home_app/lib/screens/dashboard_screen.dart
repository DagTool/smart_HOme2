// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/device_provider.dart';
import '../providers/home_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/widgets.dart';
import 'devices_tab.dart';
import 'logs_tab.dart';
import 'otp_tab.dart';
import 'members_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTab = 0;

  final List<_TabItem> _tabs = const [
    _TabItem(Icons.home_rounded, 'Tổng quan'),
    _TabItem(Icons.history_rounded, 'Lịch sử'),
    _TabItem(Icons.pin_rounded, 'OTP'),
    _TabItem(Icons.group_rounded, 'Thành viên'),
  ];

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceProvider>();
    final home = context.watch<HomeProvider>();

    final tabs = [
      const DevicesTab(),
      const LogsTab(),
      const OtpTab(),
      const MembersTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.home_rounded,
                  color: Color(0xFF3B82F6), size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  home.settings.homeName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  home.currentMember?.name ?? '',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // ESP32 status indicator
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: StatusBadge(
              label: devices.state.esp32Status == 'online'
                  ? 'Online'
                  : 'Offline',
              color: devices.state.esp32Status == 'online'
                  ? const Color(0xFF10B981)
                  : const Color(0xFF6B7280),
              pulse: devices.state.esp32Status == 'online',
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            color: const Color(0xFF1A2235),
            onSelected: (v) async {
              if (v == 'signout') {
                await context.read<AppAuthProvider>().signOut();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.white54, size: 18),
                    SizedBox(width: 8),
                    Text('Đăng xuất',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Security alert banner
          if (devices.state.securityAlert != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SecurityAlertBanner(
                message: devices.state.securityAlert!,
                onDismiss: () => devices.clearAlert(),
              ),
            ),
          Expanded(child: tabs[_currentTab]),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) => setState(() => _currentTab = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF3B82F6),
          unselectedItemColor: Colors.white30,
          selectedLabelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: _tabs
              .map((t) => BottomNavigationBarItem(
                    icon: Icon(t.icon, size: 22),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem(this.icon, this.label);
}
