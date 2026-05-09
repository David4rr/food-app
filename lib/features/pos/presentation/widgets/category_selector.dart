import 'package:flutter/material.dart';

import '../../../../models/category.dart';

class CategorySelector extends StatelessWidget {
  final List<ProductCategory> cats;
  final String? selCat;
  final bool useCustom;
  final TextEditingController customCatCtrl;
  final void Function(String?) onChanged;
  final VoidCallback onCustomTap;
  final VoidCallback onBackToList;

  const CategorySelector({
    super.key,
    required this.cats,
    required this.selCat,
    required this.useCustom,
    required this.customCatCtrl,
    required this.onChanged,
    required this.onCustomTap,
    required this.onBackToList,
  });

  @override
  Widget build(BuildContext context) {
    if (!useCustom && cats.isNotEmpty) {
      return Wrap(
        spacing: 6,
        children: [
          ...cats.map(
            (c) => ChoiceChip(
              label: Text(c.name, style: const TextStyle(fontSize: 12)),
              selected: selCat == c.name,
              onSelected: (_) => onChanged(c.name),
              visualDensity: VisualDensity.compact,
              showCheckmark: false,
            ),
          ),
          ActionChip(
            avatar: const Icon(Icons.edit, size: 14),
            label: const Text('Custom', style: TextStyle(fontSize: 12)),
            onPressed: onCustomTap,
            visualDensity: VisualDensity.compact,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (useCustom || cats.isEmpty)
          TextFormField(
            controller: customCatCtrl,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            textCapitalization: TextCapitalization.words,
          ),
        if (useCustom)
          TextButton.icon(
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Pick from list'),
            onPressed: onBackToList,
          ),
      ],
    );
  }
}
