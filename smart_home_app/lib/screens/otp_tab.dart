// lib/screens/otp_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/device_provider.dart';
import '../widgets/widgets.dart';

class OtpTab extends StatelessWidget {
  const OtpTab({super.key});

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceProvider>();
    final state = devices.state;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Mã OTP một lần'),

        // Main OTP display
        OtpDisplay(
          otp: state.currentOtp,
          countdown: state.otpCountdown,
        ),
        const SizedBox(height: 16),

        // Copy button
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: state.currentOtp));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã sao chép OTP'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2235),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.copy_rounded, color: Color(0xFF3B82F6), size: 18),
                SizedBox(width: 8),
                Text(
                  'Sao chép mã OTP',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 24),

        // How to use
        const SectionHeader(title: 'Hướng dẫn sử dụng'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2235),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              _StepRow(
                number: '1',
                icon: Icons.phone_android_rounded,
                title: 'Xem mã OTP',
                desc: 'Mã 6 số được làm mới mỗi 30 giây theo chuẩn TOTP',
              ),
              const Divider(color: Colors.white10, height: 20),
              _StepRow(
                number: '2',
                icon: Icons.keyboard_rounded,
                title: 'Nhập vào bàn phím ESP32',
                desc: 'Gõ 6 số OTP vào keypad, nhấn # để xác nhận',
              ),
              const Divider(color: Colors.white10, height: 20),
              _StepRow(
                number: '3',
                icon: Icons.door_front_door_rounded,
                title: 'Cửa tự mở',
                desc: 'ESP32 xác thực và mở cửa trong 3 giây',
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 16),

        // Warning note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.25)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mỗi mã OTP chỉ dùng được 1 lần. Không chia sẻ mã cho người không tin tưởng.',
                  style:
                      TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String desc;

  const _StepRow({
    required this.number,
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
