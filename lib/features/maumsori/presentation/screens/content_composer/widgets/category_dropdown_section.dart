import 'package:flutter/material.dart';

import '../../../../data/models/quote_model.dart';

class CategoryDropdownSection extends StatelessWidget {
  final ContentType selectedType;
  final String? selectedCategory;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const CategoryDropdownSection({
    super.key,
    required this.selectedType,
    required this.selectedCategory,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedType == ContentType.quote) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '카테고리',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedCategory,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
