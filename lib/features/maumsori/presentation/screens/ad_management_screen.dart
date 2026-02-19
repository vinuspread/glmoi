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
  bool? _isBannerEnabled;

  // 트리거 조건별 상태
  bool? _triggerOnNavigation;
  int? _navigationFrequency;
  bool? _triggerOnPost;
  int? _postFrequency;
  bool? _triggerOnShare;
  int? _shareFrequency;
  bool? _triggerOnExit;

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
                          _navigationFrequency = config.navigationFrequency;
                          _triggerOnNavigation = config.triggerOnNavigation;
                          _triggerOnPost = config.triggerOnPost;
                          _postFrequency = config.postFrequency;
                          _triggerOnShare = config.triggerOnShare;
                          _shareFrequency = config.shareFrequency;
                          _triggerOnExit = config.triggerOnExit;
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
                                    // 트리거 조건은 별도 섹션으로 분리
                                  ],
                                ),
                              ),
                              AdSectionCard(
                                title: '전면 광고 트리거 조건',
                                description: '어떤 상황에서 전면 광고를 노출할지 설정합니다.',
                                child: Column(
                                  children: [
                                    _buildTriggerSection(
                                      title: '화면 이동 횟수',
                                      description:
                                          '사용자가 상세 화면을 N번 열 때마다 광고를 표시합니다.',
                                      value: _triggerOnNavigation ?? true,
                                      onChanged: (val) => setState(
                                        () => _triggerOnNavigation = val,
                                      ),
                                      frequency: _navigationFrequency ?? 15,
                                      onFrequencyChanged: (val) => setState(
                                        () => _navigationFrequency = val,
                                      ),
                                      frequencyOptions: const [
                                        10,
                                        15,
                                        20,
                                        25,
                                        30,
                                        35,
                                        40,
                                      ],
                                    ),
                                    const Divider(height: 32),
                                    _buildTriggerSection(
                                      title: '글 작성 후',
                                      description:
                                          '사용자가 글을 N번 작성할 때마다 광고를 표시합니다.',
                                      value: _triggerOnPost ?? false,
                                      onChanged: (val) =>
                                          setState(() => _triggerOnPost = val),
                                      frequency: _postFrequency ?? 5,
                                      onFrequencyChanged: (val) =>
                                          setState(() => _postFrequency = val),
                                      frequencyOptions: const [3, 5, 8, 10],
                                    ),
                                    const Divider(height: 32),
                                    _buildTriggerSection(
                                      title: '글 공유 후',
                                      description:
                                          '사용자가 글을 N번 공유할 때마다 광고를 표시합니다.',
                                      value: _triggerOnShare ?? false,
                                      onChanged: (val) =>
                                          setState(() => _triggerOnShare = val),
                                      frequency: _shareFrequency ?? 3,
                                      onFrequencyChanged: (val) =>
                                          setState(() => _shareFrequency = val),
                                      frequencyOptions: const [3, 5, 8, 10],
                                    ),
                                    const Divider(height: 32),
                                    SwitchListTile(
                                      title: const Text(
                                        '앱 종료 시',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        '사용자가 앱을 종료할 때마다 광고를 표시합니다.',
                                      ),
                                      value: _triggerOnExit ?? false,
                                      onChanged: (val) =>
                                          setState(() => _triggerOnExit = val),
                                      activeThumbColor: AppTheme.primaryPurple,
                                      activeTrackColor: AppTheme.primaryPurple
                                          .withValues(alpha: 0.35),
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
        isBannerEnabled: _isBannerEnabled ?? true,
        bannerAndroidUnitId: _bannerAndroidUnitIdController.text.trim(),
        bannerIosUnitId: _bannerIosUnitIdController.text.trim(),
        interstitialAndroidUnitId: _interstitialAndroidUnitIdController.text
            .trim(),
        interstitialIosUnitId: _interstitialIosUnitIdController.text.trim(),
        triggerOnNavigation: _triggerOnNavigation ?? true,
        navigationFrequency: _navigationFrequency ?? 15,
        triggerOnPost: _triggerOnPost ?? false,
        postFrequency: _postFrequency ?? 5,
        triggerOnShare: _triggerOnShare ?? false,
        shareFrequency: _shareFrequency ?? 3,
        triggerOnExit: _triggerOnExit ?? false,
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

  Widget _buildTriggerSection({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required int frequency,
    required ValueChanged<int> onFrequencyChanged,
    required List<int> frequencyOptions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(description),
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primaryPurple,
          activeTrackColor: AppTheme.primaryPurple.withValues(alpha: 0.35),
        ),
        if (value) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '노출 빈도: $frequency회마다',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: frequencyOptions.map((option) {
                    final isSelected = frequency == option;
                    return ChoiceChip(
                      label: Text('$option회'),
                      selected: isSelected,
                      onSelected: (_) => onFrequencyChanged(option),
                      selectedColor: AppTheme.primaryPurple.withValues(
                        alpha: 0.2,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryPurple
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
