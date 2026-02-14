import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CompanyInfoScreen extends StatelessWidget {
  const CompanyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회사소개'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: AppTheme.cardDecoration(elevated: true),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  '글모이',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '누구나 작가가 될 수 있는 공간',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              _InfoRow(
                label: '회사명',
                value: '(주)비누스',
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: '대표자',
                value: '한성영',
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: '사업자등록번호',
                value: '123-45-67890',
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: '주소',
                value: '서울특별시 강남구',
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: '이메일',
                value: 'vinus@vinus.co.kr',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
