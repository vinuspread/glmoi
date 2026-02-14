import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import '../widgets/maumsori_sidebar.dart';
import '../providers/config_provider.dart';
import '../../data/models/config_model.dart';
import 'ad_management/widgets/ad_management_header.dart';
import 'ad_management/widgets/ad_section_card.dart';
import 'package:app_admin/core/widgets/admin_background.dart';

class AdManagementScreen extends ConsumerStatefulWidget {
  const AdManagementScreen({super.key});

  @override
  ConsumerState<AdManagementScreen> createState() => _AdManagementScreenState();
}

class _AdManagementScreenState extends ConsumerState<AdManagementScreen> {
  // 로컬 상태 (저장 전 변경사항 관리) -> Stream 데이터를 받아서 초기화 필요
  bool? _isInterstitialEnabled;
  int? _frequency;
  bool? _isBannerEnabled;

  final _bannerAndroidUnitIdController = TextEditingController();
  final _bannerIosUnitIdController = TextEditingController();
  final _interstitialAndroidUnitIdController = TextEditingController();
  final _interstitialIosUnitIdController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _bannerAndroidUnitIdController.dispose();
    _bannerIosUnitIdController.dispose();
    _interstitialAndroidUnitIdController.dispose();
    _interstitialIosUnitIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adConfigAsync = ref.watch(adConfigProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdminBackground(
        child: Row(
          children: [
            const MaumSoriSidebar(activeRoute: '/maumsori/ads'),
            const VerticalDivider(width: 1, color: AppTheme.border),
            Expanded(
              child: Column(
                children: [
                  const AdManagementHeader(),
                  Expanded(
                    child: adConfigAsync.when(
                      data: (config) {
                        // 데이터가 로드되면 로컬 상태 초기화 (최초 1회 또는 외부 변경 시)
                        if (_isInterstitialEnabled == null) {
                          _isInterstitialEnabled = config.isInterstitialEnabled;
                          _frequency = config.interstitialFrequency;
                          _isBannerEnabled = config.isBannerEnabled;

                          _bannerAndroidUnitIdController.text =
                              config.bannerAndroidUnitId;
                          _bannerIosUnitIdController.text =
                              config.bannerIosUnitId;
                          _interstitialAndroidUnitIdController.text =
                              config.interstitialAndroidUnitId;
                          _interstitialIosUnitIdController.text =
                              config.interstitialIosUnitId;
                        }

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AdSectionCard(
                                title: '하단 고정 배너 광고',
                                description: '하단에 고정 노출되는 배너 광고를 설정합니다.',
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SwitchListTile(
                                      title: const Text(
                                        '배너 광고 활성화',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        '꺼두시면 앱 하단 배너가 노출되지 않습니다.',
                                      ),
                                      value: _isBannerEnabled ?? true,
                                      onChanged: (val) {
                                        setState(() {
                                          _isBannerEnabled = val;
                                        });
                                      },
                                      activeThumbColor: AppTheme.primaryPurple,
                                      activeTrackColor: AppTheme.primaryPurple
                                          .withValues(alpha: 0.35),
                                    ),
                                    const Divider(height: 32),
                                    TextField(
                                      decoration: const InputDecoration(
                                        labelText: '배너 Unit ID (Android)',
                                        hintText:
                                            'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx',
                                      ),
                                      controller:
                                          _bannerAndroidUnitIdController,
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      decoration: const InputDecoration(
                                        labelText: '배너 Unit ID (iOS)',
                                        hintText:
                                            'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx',
                                      ),
                                      controller: _bannerIosUnitIdController,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Tip: Unit ID를 비워두면 해당 플랫폼에서는 광고가 노출되지 않습니다.',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AdSectionCard(
                                title: '전면 광고 설정',
                                description: '화면 전환 시 노출되는 전면 광고의 동작을 제어합니다.',
                                child: Column(
                                  children: [
                                    SwitchListTile(
                                      title: const Text(
                                        '전면 광고 활성화',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        '꺼두시면 앱 전체에서 전면 광고가 노출되지 않습니다.',
                                      ),
                                      value: _isInterstitialEnabled ?? true,
                                      onChanged: (val) {
                                        setState(() {
                                          _isInterstitialEnabled = val;
                                        });
                                      },
                                      activeThumbColor: AppTheme.primaryPurple,
                                      activeTrackColor: AppTheme.primaryPurple
                                          .withValues(alpha: 0.35),
                                    ),
                                    const Divider(height: 32),
                                    TextField(
                                      decoration: const InputDecoration(
                                        labelText: '전면 Unit ID (Android)',
                                        hintText:
                                            'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx',
                                      ),
                                      controller:
                                          _interstitialAndroidUnitIdController,
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      decoration: const InputDecoration(
                                        labelText: '전면 Unit ID (iOS)',
                                        hintText:
                                            'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx',
                                      ),
                                      controller:
                                          _interstitialIosUnitIdController,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Tip: Unit ID를 비워두면 해당 플랫폼에서는 전면 광고가 노출되지 않습니다.',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Divider(height: 32),
                                    ListTile(
                                      title: Text(
                                        '광고 노출 빈도: ${_frequency ?? 5}회마다',
                                      ),
                                      subtitle: const Text(
                                        '사용자가 화면을 N번 이동할 때마다 광고를 노출합니다.',
                                      ),
                                    ),
                                    Slider(
                                      value: (_frequency ?? 5).toDouble(),
                                      min: 1,
                                      max: 20,
                                      divisions: 19,
                                      label: '${_frequency ?? 5}회',
                                      activeColor: AppTheme.primaryPurple,
                                      onChanged: (val) {
                                        setState(() {
                                          _frequency = val.round();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => _saveConfig(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(_isSaving ? '저장 중...' : '설정 저장'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      final newConfig = AdConfigModel(
        isInterstitialEnabled: _isInterstitialEnabled ?? true,
        interstitialFrequency: _frequency ?? 5,
        isBannerEnabled: _isBannerEnabled ?? true,
        bannerAndroidUnitId: _bannerAndroidUnitIdController.text.trim(),
        bannerIosUnitId: _bannerIosUnitIdController.text.trim(),
        interstitialAndroidUnitId: _interstitialAndroidUnitIdController.text
            .trim(),
        interstitialIosUnitId: _interstitialIosUnitIdController.text.trim(),
      );

      await ref.read(configControllerProvider).updateAdConfig(newConfig);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('광고 설정이 저장되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
