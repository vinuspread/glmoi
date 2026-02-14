import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/image_asset_model.dart';
import '../../../../data/models/quote_model.dart';
import 'action_buttons_row.dart';
import 'background_image_picker.dart';
import 'category_dropdown_section.dart';
import 'text_fields_section.dart';
import 'type_font_section.dart';

class ComposerInputForm extends StatelessWidget {
  final ContentType selectedType;
  final ValueChanged<ContentType> onTypeSelected;

  final MalmoiLength selectedMalmoiLength;
  final ValueChanged<MalmoiLength> onMalmoiLengthSelected;
  final ContentFont selectedFont;
  final ValueChanged<ContentFont> onFontSelected;
  final ContentFontThickness selectedFontThickness;
  final ValueChanged<ContentFontThickness> onFontThicknessSelected;

  final String? selectedCategory;
  final List<DropdownMenuItem<String>> categoryItems;
  final ValueChanged<String?> onCategoryChanged;

  final TextEditingController contentController;
  final TextEditingController authorController;
  final VoidCallback onTextChanged;
  final String? badWordsWarning;

  final AsyncValue<List<ImageAssetModel>> imagesAsync;
  final String? selectedImageUrl;
  final ValueChanged<String> onImageSelected;

  final VoidCallback onReset;
  final VoidCallback onSave;
  final bool canSave;

  const ComposerInputForm({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    required this.selectedMalmoiLength,
    required this.onMalmoiLengthSelected,
    required this.selectedFont,
    required this.onFontSelected,
    required this.selectedFontThickness,
    required this.onFontThicknessSelected,
    required this.selectedCategory,
    required this.categoryItems,
    required this.onCategoryChanged,
    required this.contentController,
    required this.authorController,
    required this.onTextChanged,
    this.badWordsWarning,
    required this.imagesAsync,
    required this.selectedImageUrl,
    required this.onImageSelected,
    required this.onReset,
    required this.onSave,
    required this.canSave,
  });

  @override
  Widget build(BuildContext context) {
    final isMalmoiShort =
        selectedType == ContentType.malmoi &&
        selectedMalmoiLength == MalmoiLength.short;
    final isMalmoiLong =
        selectedType == ContentType.malmoi &&
        selectedMalmoiLength == MalmoiLength.long;

    final isShortForm = selectedType == ContentType.quote || isMalmoiShort;
    final maxLen = isShortForm ? 200 : 2000;
    final maxLines = isShortForm ? 3 : (isMalmoiLong ? 10 : 6);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '새 글 작성',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          TypeFontSection(
            selectedType: selectedType,
            onTypeSelected: onTypeSelected,
            selectedMalmoiLength: selectedMalmoiLength,
            onMalmoiLengthSelected: onMalmoiLengthSelected,
            selectedFont: selectedFont,
            onFontSelected: onFontSelected,
            selectedFontThickness: selectedFontThickness,
            onFontThicknessSelected: onFontThicknessSelected,
          ),
          const SizedBox(height: 32),
          CategoryDropdownSection(
            selectedType: selectedType,
            selectedCategory: selectedCategory,
            items: categoryItems,
            onChanged: onCategoryChanged,
          ),
          TextFieldsSection(
            contentController: contentController,
            authorController: authorController,
            onChanged: onTextChanged,
            badWordsWarning: badWordsWarning,
            contentMaxLength: maxLen,
            contentMaxLines: maxLines,
          ),
          const SizedBox(height: 32),
          const Text(
            '배경 이미지',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          BackgroundImagePicker(
            imagesAsync: imagesAsync,
            selectedImageUrl: selectedImageUrl,
            onSelect: onImageSelected,
          ),
          const SizedBox(height: 48),
          ActionButtonsRow(onReset: onReset, onSave: onSave, canSave: canSave),
        ],
      ),
    );
  }
}
