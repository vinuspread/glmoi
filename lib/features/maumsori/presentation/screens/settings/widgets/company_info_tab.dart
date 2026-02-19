import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

class CompanyInfoTab extends StatelessWidget {
  final TextEditingController contentController;
  final bool isSaving;
  final VoidCallback onSave;

  const CompanyInfoTab({
    super.key,
    required this.contentController,
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
            '회사소개',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: contentController,
            maxLines: 15,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText:
                  '회사소개 내용을 입력하세요.\n\n예시:\n회사명: (주)글모이\n대표자: 홍길동\n사업자등록번호: 123-45-67890\n주소: 서울시 강남구...\n이메일: contact@glmoi.com',
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
