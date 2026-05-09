// lib/features/menu/presentation/product_form_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/image_service.dart';
import '../../../models/product.dart';
import '../providers/menu_provider.dart';
import '../providers/category_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _customCategoryCtrl;
  String? _imagePath;
  String? _selectedCategory;
  bool _saving = false;
  bool _useCustomCategory = false;
  List<AddOn> _addOns = [];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toStringAsFixed(0) ?? '');
    _customCategoryCtrl = TextEditingController(text: '');
    _selectedCategory = p?.category;
    _imagePath = p?.imagePath;
    _addOns = List.from(p?.addOns ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
    );
    if (picked != null) {
      final path = await ImageService.savePickedImage(picked.path);
      setState(() => _imagePath = path);
    }
  }

  Future<void> _addAddOn() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');
    final result = await showDialog<AddOn>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Add-on'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. No corn, Extra cheese',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Extra Price',
                prefixText: 'Rp ',
                hintText: '0',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(
                ctx,
                AddOn(
                  id: const Uuid().v4(),
                  name: name,
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    priceCtrl.dispose();
    if (result != null) setState(() => _addOns = [..._addOns, result]);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final category = _useCustomCategory
        ? _customCategoryCtrl.text.trim()
        : (_selectedCategory ?? '');

    if (_isEditing) {
      await ref
          .read(menuNotifierProvider.notifier)
          .updateProduct(
            widget.product!.copyWith(
              name: name,
              price: price,
              category: category,
              imagePath: _imagePath,
              clearImage: _imagePath == null,
              addOns: _addOns,
            ),
          );
    } else {
      await ref
          .read(menuNotifierProvider.notifier)
          .addProduct(
            name: name,
            price: price,
            category: category,
            imagePath: _imagePath,
            addOns: _addOns,
          );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final categories = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'New Product'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      _imagePath != null && ImageService.fileExists(_imagePath)
                      ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 32,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                prefixIcon: Icon(Icons.fastfood_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixIcon: Icon(Icons.attach_money),
                prefixText: 'Rp ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter valid price';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Category',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (!_useCustomCategory && categories.isNotEmpty) ...[
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  separatorBuilder: (_, i) => const SizedBox(width: 8),
                  itemCount: categories.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i < categories.length) {
                      final cat = categories[i];
                      final selected = _selectedCategory == cat.name;
                      return ChoiceChip(
                        label: Text(cat.name),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _selectedCategory = cat.name;
                          _customCategoryCtrl.clear();
                        }),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      );
                    }
                    return ActionChip(
                      avatar: const Icon(Icons.edit, size: 16),
                      label: const Text('Custom'),
                      onPressed: () =>
                          setState(() => _useCustomCategory = true),
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
              ),
              if (_useCustomCategory) const SizedBox(height: 8),
            ],
            if (_useCustomCategory || categories.isEmpty)
              TextFormField(
                controller: _customCategoryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  prefixIcon: Icon(Icons.category_outlined),
                  hintText: 'e.g. Makanan, Minuman...',
                ),
                textCapitalization: TextCapitalization.words,
              ),
            if (_useCustomCategory)
              TextButton.icon(
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Pick from list'),
                onPressed: () => setState(() => _useCustomCategory = false),
              ),
            const SizedBox(height: 24),
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
                  onPressed: _addAddOn,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_addOns.isNotEmpty) const SizedBox(height: 4),
            ..._addOns.map(
              (a) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(a.name, style: const TextStyle(fontSize: 14)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (a.price > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '+Rp ${a.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: Icon(Icons.close, size: 18, color: colors.error),
                        onPressed: () => setState(
                          () => _addOns = _addOns
                              .where((x) => x.id != a.id)
                              .toList(),
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isEditing ? 'Update Product' : 'Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}
