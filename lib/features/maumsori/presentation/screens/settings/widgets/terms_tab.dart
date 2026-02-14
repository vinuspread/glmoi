import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class TermsTab extends StatelessWidget {
  final TextEditingController termsController;
  final TextEditingController privacyController;
  final bool isSaving;
  final VoidCallback onSave;

  const TermsTab({
    super.key,
    required this.termsController,
    required this.privacyController,
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
            '이용약관',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: termsController,
            maxLines: 10,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '이용약관 내용을 입력하세요.',
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '개인정보 처리방침',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: privacyController,
            maxLines: 10,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '개인정보 처리방침 내용을 입력하세요.',
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
