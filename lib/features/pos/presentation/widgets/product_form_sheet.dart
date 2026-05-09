import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/image_service.dart';
import '../../../../models/product.dart';
import '../../../menu/providers/category_provider.dart';
import '../../../menu/providers/menu_provider.dart';
import 'addon_dialog.dart';
import 'addon_list.dart';

void showProductFormSheet(
  BuildContext context,
  WidgetRef ref,
  Product? product,
) {
  final isEdit = product != null;
  final nameCtrl = TextEditingController(text: product?.name ?? '');
  final priceCtrl = TextEditingController(
    text: product?.price.toStringAsFixed(0) ?? '',
  );
  final customCatCtrl = TextEditingController();
  String? imagePath = product?.imagePath;
  String? selCat = product?.category;
  bool useCustom = false;
  final formKey = GlobalKey<FormState>();
  List<AddOn> addOns = product != null ? List.from(product.addOns) : [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        final cats = ref.watch(categoryListProvider);

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProductImagePicker(
                      imagePath: imagePath,
                      onPick: () async {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800,
                        );
                        if (picked != null) {
                          final path = await ImageService.savePickedImage(
                            picked.path,
                          );
                          setSheetState(() => imagePath = path);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _ProductNameField(controller: nameCtrl),
                    const SizedBox(height: 12),
                    _ProductPriceField(controller: priceCtrl),
                    const SizedBox(height: 12),
                    _CategorySelector(
                      cats: cats,
                      selCat: selCat,
                      useCustom: useCustom,
                      customCatCtrl: customCatCtrl,
                      onChanged: (v) => setSheetState(() {
                        selCat = v;
                        customCatCtrl.clear();
                      }),
                      onCustomTap: () => setSheetState(() => useCustom = true),
                      onBackToList: () =>
                          setSheetState(() => useCustom = false),
                    ),
                    const SizedBox(height: 16),
                    _AddonSection(
                      addOns: addOns,
                      onAdd: () async {
                        final result = await showAddOnDialog(ctx);
                        if (result != null) {
                          setSheetState(() => addOns = [...addOns, result]);
                        }
                      },
                      onDelete: (a) => setSheetState(
                        () =>
                            addOns = addOns.where((x) => x.id != a.id).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SaveButton(
                      isEdit: isEdit,
                      formKey: formKey,
                      nameCtrl: nameCtrl,
                      priceCtrl: priceCtrl,
                      useCustom: useCustom,
                      customCatCtrl: customCatCtrl,
                      selCat: selCat,
                      imagePath: imagePath,
                      addOns: addOns,
                      product: product,
                      menuNotifier: ref.read(menuNotifierProvider.notifier),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _ProductImagePicker extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onPick;

  const _ProductImagePicker({required this.imagePath, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: GestureDetector(
        onTap: onPick,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: imagePath != null && ImageService.fileExists(imagePath)
              ? Image.file(File(imagePath!), fit: BoxFit.cover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 28,
                      color: colors.onSurfaceVariant,
                    ),
                    Text(
                      'Photo',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProductNameField extends StatelessWidget {
  final TextEditingController controller;

  const _ProductNameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Product Name',
        prefixIcon: Icon(Icons.fastfood_outlined),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }
}

class _ProductPriceField extends StatelessWidget {
  final TextEditingController controller;

  const _ProductPriceField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Price',
        prefixIcon: Icon(Icons.attach_money),
        prefixText: 'Rp ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        final n = double.tryParse(v ?? '');
        return n == null || n <= 0 ? 'Invalid price' : null;
      },
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List cats;
  final String? selCat;
  final bool useCustom;
  final TextEditingController customCatCtrl;
  final void Function(String?) onChanged;
  final VoidCallback onCustomTap;
  final VoidCallback onBackToList;

  const _CategorySelector({
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

class _AddonSection extends StatelessWidget {
  final List<AddOn> addOns;
  final VoidCallback onAdd;
  final void Function(AddOn) onDelete;

  const _AddonSection({
    required this.addOns,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Add-ons',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        if (addOns.isNotEmpty) ...[
          const SizedBox(height: 4),
          AddonList(addOns: addOns, onDelete: onDelete),
        ],
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isEdit;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  final bool useCustom;
  final TextEditingController customCatCtrl;
  final String? selCat;
  final String? imagePath;
  final List<AddOn> addOns;
  final Product? product;
  final MenuNotifier menuNotifier;

  const _SaveButton({
    required this.isEdit,
    required this.formKey,
    required this.nameCtrl,
    required this.priceCtrl,
    required this.useCustom,
    required this.customCatCtrl,
    required this.selCat,
    required this.imagePath,
    required this.addOns,
    required this.product,
    required this.menuNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () async {
        if (!formKey.currentState!.validate()) return;
        final name = nameCtrl.text.trim();
        final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
        final cat = useCustom ? customCatCtrl.text.trim() : (selCat ?? '');

        if (isEdit) {
          await menuNotifier.updateProduct(
            product!.copyWith(
              name: name,
              price: price,
              category: cat,
              imagePath: imagePath,
              clearImage: imagePath == null,
              addOns: addOns,
            ),
          );
        } else {
          await menuNotifier.addProduct(
            name: name,
            price: price,
            category: cat,
            imagePath: imagePath,
            addOns: addOns,
          );
        }

        if (context.mounted) Navigator.pop(context);
      },
      icon: const Icon(Icons.check),
      label: Text(isEdit ? 'Update' : 'Add Product'),
    );
  }
}
