import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용약관'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: AppTheme.cardDecoration(elevated: true),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '이용약관',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '최종 수정일: 2026년 2월 15일',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: '제1조 (목적)',
                content:
                    '본 약관은 글모이(이하 "서비스")를 이용함에 있어 이용자와 회사 간의 권리, 의무 및 책임 사항을 규정함을 목적으로 합니다.',
              ),
              _buildSection(
                context,
                title: '제2조 (정의)',
                content:
                    '1. "서비스"란 글모이 애플리케이션을 통해 제공되는 모든 서비스를 의미합니다.\n2. "회원"이란 본 약관에 동의하고 서비스를 이용하는 자를 의미합니다.\n3. "글"이란 회원이 서비스에 게시한 텍스트 및 이미지를 의미합니다.',
              ),
              _buildSection(
                context,
                title: '제3조 (약관의 효력 및 변경)',
                content:
                    '1. 본 약관은 서비스 화면에 게시하거나 기타의 방법으로 회원에게 공지함으로써 효력이 발생합니다.\n2. 회사는 필요한 경우 본 약관을 변경할 수 있으며, 변경된 약관은 제1항과 같은 방법으로 공지합니다.',
              ),
              _buildSection(
                context,
                title: '제4조 (회원 가입)',
                content:
                    '1. 회원 가입은 이용자가 약관에 동의하고 회사가 정한 가입 양식에 따라 회원정보를 기입함으로써 완료됩니다.\n2. 회사는 다음 각 호에 해당하는 경우 회원 가입을 거절하거나 제한할 수 있습니다.\n   - 타인의 명의를 도용한 경우\n   - 허위 정보를 기재한 경우\n   - 기타 회사가 정한 이용 요건을 충족하지 못한 경우',
              ),
              _buildSection(
                context,
                title: '제5조 (서비스 이용)',
                content:
                    '1. 회원은 본 약관 및 관련 법령을 준수하여야 합니다.\n2. 회원은 다음 행위를 하여서는 안 됩니다.\n   - 타인의 개인정보를 도용하는 행위\n   - 허위 사실을 유포하는 행위\n   - 욕설, 비방, 음란물 등을 게시하는 행위\n   - 기타 법령에 위반되는 행위',
              ),
              _buildSection(
                context,
                title: '제6조 (서비스의 중단)',
                content:
                    '회사는 시스템 점검, 보수, 교체 등의 사유로 서비스 제공을 일시 중단할 수 있으며, 이 경우 사전에 공지합니다.',
              ),
              _buildSection(
                context,
                title: '제7조 (면책 조항)',
                content:
                    '1. 회사는 천재지변, 전쟁 등 불가항력적인 사유로 인한 서비스 중단에 대해 책임을 지지 않습니다.\n2. 회사는 회원의 귀책사유로 인한 서비스 이용 장애에 대해 책임을 지지 않습니다.',
              ),
              _buildSection(
                context,
                title: '제8조 (분쟁 해결)',
                content:
                    '본 약관과 관련하여 분쟁이 발생한 경우 회사의 본사 소재지를 관할하는 법원을 전속 관할 법원으로 합니다.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
