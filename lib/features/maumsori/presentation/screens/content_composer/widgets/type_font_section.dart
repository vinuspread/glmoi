import 'package:flutter/material.dart';
import 'package:app_admin/core/theme/app_theme.dart';

import '../../../../data/models/quote_model.dart';

class TypeFontSection extends StatelessWidget {
  final ContentType selectedType;
  final ValueChanged<ContentType> onTypeSelected;

  final MalmoiLength selectedMalmoiLength;
  final ValueChanged<MalmoiLength> onMalmoiLengthSelected;

  final ContentFont selectedFont;
  final ValueChanged<ContentFont> onFontSelected;

  final ContentFontThickness selectedFontThickness;
  final ValueChanged<ContentFontThickness> onFontThicknessSelected;

  const TypeFontSection({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    required this.selectedMalmoiLength,
    required this.onMalmoiLengthSelected,
    required this.selectedFont,
    required this.onFontSelected,
    required this.selectedFontThickness,
    required this.onFontThicknessSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '콘텐츠 유형',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _TypeChip(
              label: '한줄명언',
              isSelected: selectedType == ContentType.quote,
              onTap: () => onTypeSelected(ContentType.quote),
            ),
            const SizedBox(width: 12),
            _TypeChip(
              label: '좋은생각',
              isSelected: selectedType == ContentType.thought,
              onTap: () => onTypeSelected(ContentType.thought),
            ),
            const SizedBox(width: 12),
            _TypeChip(
              label: '글모이',
              isSelected: selectedType == ContentType.malmoi,
              onTap: () => onTypeSelected(ContentType.malmoi),
            ),
          ],
        ),

        if (selectedType == ContentType.malmoi) ...[
          const SizedBox(height: 16),
          const Text(
            '글모이 옵션',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TypeChip(
                label: '짧은글',
                isSelected: selectedMalmoiLength == MalmoiLength.short,
                onTap: () => onMalmoiLengthSelected(MalmoiLength.short),
              ),
              const SizedBox(width: 12),
              _TypeChip(
                label: '긴글',
                isSelected: selectedMalmoiLength == MalmoiLength.long,
                onTap: () => onMalmoiLengthSelected(MalmoiLength.long),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          '폰트',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _TypeChip(
              label: '고딕',
              isSelected: selectedFont == ContentFont.gothic,
              onTap: () => onFontSelected(ContentFont.gothic),
            ),
            const SizedBox(width: 12),
            _TypeChip(
              label: '명조',
              isSelected: selectedFont == ContentFont.serif,
              onTap: () => onFontSelected(ContentFont.serif),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          '두께',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _TypeChip(
              label: '보통',
              isSelected: selectedFontThickness == ContentFontThickness.regular,
              onTap: () =>
                  onFontThicknessSelected(ContentFontThickness.regular),
            ),
            const SizedBox(width: 12),
            _TypeChip(
              label: '두껍게',
              isSelected: selectedFontThickness == ContentFontThickness.thick,
              onTap: () => onFontThicknessSelected(ContentFontThickness.thick),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
