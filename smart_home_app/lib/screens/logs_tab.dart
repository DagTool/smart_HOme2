// lib/screens/logs_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../widgets/widgets.dart';

class LogsTab extends StatelessWidget {
  const LogsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceProvider>();
    final logs = devices.logs;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SectionHeader(
            title: 'Lịch sử truy cập',
            trailing: '${logs.length} bản ghi',
          ),
        ),
        if (logs.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, color: Colors.white24, size: 48),
                  SizedBox(height: 12),
                  Text('Chưa có lịch sử',
                      style: TextStyle(color: Colors.white38)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: logs.length,
              itemBuilder: (_, i) {
                final log = logs[i];
                return LogTile(
                  action: log.action,
                  time: log.time,
                  method: log.method,
                  user: log.user,
                );
              },
            ),
          ),
      ],
    );
  }
}
