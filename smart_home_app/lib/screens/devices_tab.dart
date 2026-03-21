// lib/screens/devices_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/device_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/widgets.dart';

class DevicesTab extends StatelessWidget {
  const DevicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceProvider>();
    final home = context.watch<HomeProvider>();
    final state = devices.state;

    if (devices.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF3B82F6),
      backgroundColor: const Color(0xFF1A2235),
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Last event
          if (state.lastEvent.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2235),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: Colors.white38, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sự kiện cuối: ${state.lastEvent}',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

          // Device Grid
          const SectionHeader(title: 'Điều khiển thiết bị'),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              DeviceCard(
                label: 'Đèn',
                icon: Icons.lightbulb_rounded,
                active: state.light,
                accentColor: const Color(0xFFF59E0B),
                subtitle: state.light ? 'Đang bật' : 'Đã tắt',
                onTap: () => devices.toggleLight(),
              ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),
              DeviceCard(
                label: 'Điều hoà',
                icon: Icons.ac_unit_rounded,
                active: state.ac,
                accentColor: const Color(0xFF06B6D4),
                subtitle: state.ac ? 'Đang chạy' : 'Đã tắt',
                onTap: () => devices.toggleAC(),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              DeviceCard(
                label: 'Cửa ra vào',
                icon: Icons.door_front_door_rounded,
                active: state.door,
                accentColor: const Color(0xFF10B981),
                subtitle: state.door ? 'Đang mở' : 'Đã đóng',
                onTap: () => devices.toggleDoor(),
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
              DeviceCard(
                label: 'Cửa sổ',
                icon: Icons.window_rounded,
                active: state.window,
                accentColor: const Color(0xFF8B5CF6),
                subtitle: state.window ? 'Đang mở' : 'Đã đóng',
                onTap: () => devices.toggleWindow(),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            ],
          ),
          const SizedBox(height: 20),

          // RFID Cards info
          const SectionHeader(title: 'Thẻ RFID đã đăng ký'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2235),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.credit_card_rounded,
                      color: Color(0xFF3B82F6), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.cardCount} thẻ đã đăng ký',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.registeredCards.isEmpty ||
                                state.registeredCards == 'No cards'
                            ? 'Chưa có thẻ nào'
                            : state.registeredCards,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 20),

          // Password management (Admin only)
          if (home.isAdmin) ...[
            SectionHeader(
              title: 'Bảo mật',
              trailing: 'Đổi mật khẩu',
              onTrailingTap: () => _showChangePasswordDialog(context, devices),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2235),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mật khẩu master (PIN)',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.masterPassword.isNotEmpty
                              ? '•' * state.masterPassword.length
                              : 'Chưa cài đặt',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        _showChangePasswordDialog(context, devices),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Đổi',
                        style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(
      BuildContext context, DeviceProvider devices) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final hasOldPass = devices.state.masterPassword.isNotEmpty;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đổi mật khẩu master',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasOldPass) ...[
              AppTextField(
                controller: oldPassCtrl,
                label: 'Mật khẩu cũ',
                obscure: true,
                prefixIcon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 12),
            ],
            AppTextField(
              controller: newPassCtrl,
              label: 'Mật khẩu mới (≥6 ký tự)',
              obscure: true,
              prefixIcon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: confirmCtrl,
              label: 'Xác nhận',
              obscure: true,
              prefixIcon: Icons.lock_outline_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (hasOldPass && oldPassCtrl.text != devices.state.masterPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mật khẩu cũ không chính xác'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
                return;
              }

              final np = newPassCtrl.text;
              if (np.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mật khẩu phải có ít nhất 6 ký tự')),
                );
                return;
              }
              if (np != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mật khẩu không khớp')),
                );
                return;
              }
              devices.changeMasterPassword(np);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã cập nhật mật khẩu'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
