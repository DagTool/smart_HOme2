// lib/screens/members_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/home_provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class MembersTab extends StatelessWidget {
  const MembersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final auth = context.watch<AppAuthProvider>();
    final isAdmin = home.isAdmin;
    final members = home.members;
    final code = home.settings.inviteCode;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Invite code card (admin only)
        if (isAdmin) ...[
          const SectionHeader(title: 'Mã mời thành viên'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2235),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chia sẻ mã này để mời',
                      style:
                          TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => _confirmRegenerate(context, home),
                      child: const Row(
                        children: [
                          Icon(Icons.refresh_rounded,
                              color: Color(0xFF3B82F6), size: 16),
                          SizedBox(width: 4),
                          Text('Làm mới',
                              style: TextStyle(
                                  color: Color(0xFF3B82F6), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép mã mời'),
                        backgroundColor: Color(0xFF10B981),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0E1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          code.isEmpty ? '--------' : code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Icon(Icons.copy_rounded,
                            color: Color(0xFF3B82F6), size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 20),
        ],

        // Members list
        SectionHeader(
          title: 'Thành viên (${members.length})',
        ),
        ...members.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final isSelf = m.uid == auth.user?.uid;
          return _MemberTile(
            member: m,
            isSelf: isSelf,
            isAdminViewing: isAdmin,
            onRemove: isAdmin && !isSelf
                ? () => _confirmRemove(context, home, m)
                : null,
          ).animate().fadeIn(delay: Duration(milliseconds: 50 * i));
        }),

        const SizedBox(height: 20),

        // Change account password section
        const SectionHeader(title: 'Tài khoản'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2235),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              _AccountRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: auth.user?.email ?? '-',
              ),
              const Divider(color: Colors.white10, height: 20),
              GestureDetector(
                onTap: () =>
                    _showChangeAccountPasswordDialog(context, auth),
                child: const _AccountRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Đổi mật khẩu tài khoản',
                  value: 'Nhấn để đổi',
                  valueColor: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 40),
      ],
    );
  }

  void _confirmRemove(
      BuildContext context, HomeProvider home, Member m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2235),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xoá thành viên?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Xoá ${m.name} (${m.email}) khỏi nhà?',
          style: const TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              home.removeMember(m.uid);
              Navigator.pop(context);
            },
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }

  void _confirmRegenerate(BuildContext context, HomeProvider home) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2235),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Làm mới mã mời?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Mã cũ sẽ mất hiệu lực. Thành viên đã tham gia sẽ không bị ảnh hưởng.',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              home.regenerateCode();
              Navigator.pop(context);
            },
            child: const Text('Làm mới'),
          ),
        ],
      ),
    );
  }

  void _showChangeAccountPasswordDialog(
      BuildContext context, AppAuthProvider auth) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A2235),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Đổi mật khẩu tài khoản',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: currentCtrl,
                label: 'Mật khẩu hiện tại',
                obscure: true,
                prefixIcon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: newCtrl,
                label: 'Mật khẩu mới',
                obscure: true,
                prefixIcon: Icons.lock_rounded,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: confirmCtrl,
                label: 'Xác nhận mật khẩu mới',
                obscure: true,
                prefixIcon: Icons.lock_rounded,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ',
                  style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Mật khẩu không khớp')),
                        );
                        return;
                      }
                      if (newCtrl.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Tối thiểu 6 ký tự')),
                        );
                        return;
                      }
                      setState(() => loading = true);
                      try {
                        // Re-authenticate rồi đổi mật khẩu
                        final cred =
                            EmailAuthProvider.credential(
                          email: auth.user?.email ?? '',
                          password: currentCtrl.text,
                        );
                        await auth.user
                            ?.reauthenticateWithCredential(cred);
                        await auth.user
                            ?.updatePassword(newCtrl.text);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã đổi mật khẩu thành công'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: $e'),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                      setState(() => loading = false);
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Member member;
  final bool isSelf;
  final bool isAdminViewing;
  final VoidCallback? onRemove;

  const _MemberTile({
    required this.member,
    required this.isSelf,
    required this.isAdminViewing,
    this.onRemove,
  });

  Color get _roleColor {
    switch (member.role) {
      case 'admin':
        return const Color(0xFFF59E0B);
      case 'member':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get _roleLabel {
    switch (member.role) {
      case 'admin':
        return 'Admin';
      case 'member':
        return 'Thành viên';
      default:
        return 'Khách';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelf
              ? const Color(0xFF3B82F6).withOpacity(0.3)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _roleColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                member.name.isNotEmpty
                    ? member.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: _roleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Bạn',
                            style: TextStyle(
                                color: Color(0xFF3B82F6), fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          // Role badge
          StatusBadge(label: _roleLabel, color: _roleColor),

          // Remove button (admin only)
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.person_remove_rounded,
                  color: Color(0xFFEF4444), size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white38,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
