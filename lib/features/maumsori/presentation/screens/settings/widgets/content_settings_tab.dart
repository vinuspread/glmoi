import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';
import 'category_chip.dart';
import 'bad_words_settings_section.dart';

class ContentSettingsTab extends StatelessWidget {
  final int composerFontSize;
  final ValueChanged<int> onComposerFontSizeChanged;
  final double composerLineHeight;
  final ValueChanged<double> onComposerLineHeightChanged;
  final double composerDimStrength;
  final ValueChanged<double> onComposerDimStrengthChanged;
  final String composerFontStyle;
  final ValueChanged<String> onComposerFontStyleChanged;

  final List<String> categories;
  final TextEditingController newCategoryController;
  final VoidCallback onAddCategory;
  final Future<void> Function(String oldValue) onEditCategory;
  final VoidCallback Function(String value) onDeleteCategory;

  final bool isSaving;
  final VoidCallback onSave;

  final bool showSyncToProd;
  final bool isSyncingToProd;
  final VoidCallback onSyncToProd;

  const ContentSettingsTab({
    super.key,
    required this.composerFontSize,
    required this.onComposerFontSizeChanged,
    required this.composerLineHeight,
    required this.onComposerLineHeightChanged,
    required this.composerDimStrength,
    required this.onComposerDimStrengthChanged,
    required this.composerFontStyle,
    required this.onComposerFontStyleChanged,
    required this.categories,
    required this.newCategoryController,
    required this.onAddCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.isSaving,
    required this.onSave,
    this.showSyncToProd = false,
    this.isSyncingToProd = false,
    required this.onSyncToProd,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '글작성 기본값',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: composerFontSize,
                  items: List.generate(15, (i) => 18 + i)
                      .map(
                        (v) => DropdownMenuItem(value: v, child: Text('$v px')),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    onComposerFontSizeChanged(v);
                  },
                  decoration: const InputDecoration(
                    labelText: '텍스트 기본 크기',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<double>(
                  value: composerLineHeight,
                  items: const [1.4, 1.5, 1.6, 1.7, 1.8, 2.0]
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v.toStringAsFixed(1)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    onComposerLineHeightChanged(v);
                  },
                  decoration: const InputDecoration(
                    labelText: '줄 간격 (Line Height)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<double>(
                  value: composerDimStrength,
                  items: List.generate(11, (i) => i / 10.0)
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v.toStringAsFixed(1)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    onComposerDimStrengthChanged(v);
                  },
                  decoration: const InputDecoration(
                    labelText: '배경 딤 강도 (Dim)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: composerFontStyle,
                  items: const [
                    DropdownMenuItem(value: 'gothic', child: Text('고딕')),
                    DropdownMenuItem(value: 'serif', child: Text('명조')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    onComposerFontStyleChanged(v);
                  },
                  decoration: const InputDecoration(
                    labelText: '폰트',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),
          const Text(
            '카테고리 관리',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: newCategoryController,
                        decoration: const InputDecoration(
                          labelText: '새 카테고리',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => onAddCategory(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: onAddCategory,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('추가'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (categories.isEmpty)
                  const Text(
                    '카테고리가 없습니다.\n위 입력창에서 추가해주세요.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: categories
                        .map(
                          (c) => CategoryChip(
                            label: c,
                            onEdit: () => onEditCategory(c),
                            onDelete: onDeleteCategory(c),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 48),
          const BadWordsSettingsSection(),

          if (showSyncToProd) ...[
            const SizedBox(height: 48),
            const Text(
              '운영 반영 (DEV → PROD)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '이미지/콘텐츠는 제외하고, 설정값만 PROD로 복사합니다.\n'
              '반영 대상: config/app_config, config/ad_config, config/terms_config, admin_settings/bad_words',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: isSyncingToProd ? null : onSyncToProd,
                icon: isSyncingToProd
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined, size: 18),
                label: Text(isSyncingToProd ? '반영 중...' : 'PROD로 설정값 반영'),
              ),
            ),
          ],

          const SizedBox(height: 32),
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
