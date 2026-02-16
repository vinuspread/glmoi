import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/repositories/config_repository.dart';
import '../../../../core/data/models/config_model.dart';

// ✅ Provider를 전역으로 정의 (무한 로딩 버그 수정)
final companyInfoProvider = StreamProvider<CompanyInfoModel>((ref) {
  return ref.watch(configRepositoryProvider).getCompanyInfoConfig();
});

class CompanyInfoScreen extends ConsumerWidget {
  const CompanyInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyInfoAsync = ref.watch(companyInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('회사소개'),
      ),
      body: companyInfoAsync.when(
        data: (companyInfo) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: AppTheme.cardDecoration(elevated: true),
              padding: const EdgeInsets.all(20),
              child: Text(
                companyInfo.content.isNotEmpty
                    ? companyInfo.content
                    : '회사소개 정보가 아직 등록되지 않았습니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.8,
                      color: companyInfo.content.isNotEmpty
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          print('ERROR in company_info_screen: $error');
          print('STACK: $stack');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '회사소개를 불러올 수 없습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
