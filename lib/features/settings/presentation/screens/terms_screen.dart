import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/repositories/config_repository.dart';
import '../../../../core/data/models/config_model.dart';

// ✅ Provider를 전역으로 정의 (무한 로딩 버그 수정)
final termsConfigProvider = StreamProvider<TermsConfigModel>((ref) {
  return ref.watch(configRepositoryProvider).getTermsConfig();
});

class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsConfigAsync = ref.watch(termsConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('이용약관'),
      ),
      body: termsConfigAsync.when(
        data: (termsConfig) {
          final termsOfService = termsConfig.termsOfService;
          final privacyPolicy = termsConfig.privacyPolicy;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 이용약관
                Container(
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
                      const SizedBox(height: 24),
                      Text(
                        termsOfService.isNotEmpty
                            ? termsOfService
                            : '이용약관이 아직 등록되지 않았습니다.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 개인정보 처리방침
                Container(
                  decoration: AppTheme.cardDecoration(elevated: true),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '개인정보 처리방침',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        privacyPolicy.isNotEmpty
                            ? privacyPolicy
                            : '개인정보 처리방침이 아직 등록되지 않았습니다.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '이용약관을 불러올 수 없습니다.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
