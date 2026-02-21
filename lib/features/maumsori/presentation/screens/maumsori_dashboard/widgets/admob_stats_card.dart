import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import '../../../providers/admob_provider.dart';
import '../../../../data/repositories/admob_repository.dart';

class AdMobStatsCard extends ConsumerWidget {
  const AdMobStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(admobStatsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.monetization_on,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AdMob 수익',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () async {
                  try {
                    await ref.read(admobRepositoryProvider).refreshStats();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('AdMob 통계 업데이트 중...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      final errorMessage =
                          e.toString().contains('FirebaseFunctionsException')
                          ? e.toString().split(':').last.trim()
                          : e.toString();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('AdMob 데이터 가져오기 실패: $errorMessage'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                          action: SnackBarAction(
                            label: '확인',
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                        ),
                      );
                    }
                  }
                },
                tooltip: '새로고침',
              ),
            ],
          ),
          const SizedBox(height: 20),
          statsAsync.when(
            data: (stats) {
              if (stats == null) {
                return const Center(child: Text('데이터를 불러오는 중...'));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stats.schedulerError) _SchedulerErrorBanner(stats: stats),
                  Text(
                    stats.formattedEarnings,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.startDate} ~ ${stats.endDate}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricItem(
                          label: '노출수',
                          value: stats.impressions.toString(),
                        ),
                      ),
                      Expanded(
                        child: _MetricItem(
                          label: '클릭수',
                          value: stats.clicks.toString(),
                        ),
                      ),
                      Expanded(
                        child: _MetricItem(
                          label: 'eCPM',
                          value: stats.formattedEcpm,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text(
                '오류: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchedulerErrorBanner extends StatelessWidget {
  final dynamic stats;

  const _SchedulerErrorBanner({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isTokenExpired = stats.isTokenExpired as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isTokenExpired
                  ? '⚠️ Token 만료 — get-admob-token.js 실행 후 Firestore 업데이트 필요'
                  : '⚠️ 자동 업데이트 실패 — 새로고침 버튼으로 수동 갱신하세요',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
