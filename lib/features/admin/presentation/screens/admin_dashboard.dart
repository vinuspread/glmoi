import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('아름다운 글을 모았습니다. 글모이'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () {}),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text("CMS Menu")),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('이미지 풀 관리'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('콘텐츠 등록'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings_remote),
              title: const Text('원격 설정 (광고/푸시)'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '관리자 시스템 대시보드', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            Text('좌측 메뉴를 선택하여 작업을 시작하세요.', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
