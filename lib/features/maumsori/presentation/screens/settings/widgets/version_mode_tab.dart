import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class VersionModeTab extends StatelessWidget {
  final TextEditingController minVersionController;
  final TextEditingController latestVersionController;
  final TextEditingController maintenanceMsgController;
  final bool isMaintenance;
  final ValueChanged<bool> onMaintenanceChanged;
  final bool isSaving;
  final VoidCallback onSave;

  const VersionModeTab({
    super.key,
    required this.minVersionController,
    required this.latestVersionController,
    required this.maintenanceMsgController,
    required this.isMaintenance,
    required this.onMaintenanceChanged,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '버전 관리',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minVersionController,
                  decoration: const InputDecoration(
                    labelText: '최소 지원 버전',
                    border: OutlineInputBorder(),
                    hintText: '1.0.0',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: latestVersionController,
                  decoration: const InputDecoration(
                    labelText: '최신 버전',
                    border: OutlineInputBorder(),
                    hintText: '1.0.0',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            '점검 모드',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('서버 점검 모드 활성화'),
            subtitle: const Text('활성화 시 사용자 앱 접근이 차단됩니다.'),
            value: isMaintenance,
            onChanged: onMaintenanceChanged,
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.red,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: maintenanceMsgController,
            decoration: const InputDecoration(
              labelText: '점검 메시지',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
              ),
              child: Text(isSaving ? '저장 중...' : '저장'),
            ),
          ),
        ],
      ),
    );
  }
}
