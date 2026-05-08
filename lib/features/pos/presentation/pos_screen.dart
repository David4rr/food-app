// lib/features/pos/presentation/pos_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/image_service.dart';
import '../../../models/product.dart';
import '../../menu/providers/menu_provider.dart';
import '../../menu/providers/category_provider.dart';
import '../providers/checkout_provider.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(filteredProductsProvider);
    final cats = ref.watch(categoriesProvider);
    final selCat = ref.watch(selectedCategoryProvider);
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dapurku'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: () => _showProductForm(context, ref, product: null),
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Manage Categories',
            onPressed: () => _showCategorySheet(context, ref),
          ),
          if (cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear cart',
              onPressed: () => ref.read(cartProvider.notifier).clear(),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search, size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: cats.length,
              separatorBuilder: (_, i) => const SizedBox(width: 6),
              itemBuilder: (ctx, i) {
                final cat = cats[i];
                final sel = cat == selCat;
                return ChoiceChip(
                  label: Text(cat, style: TextStyle(fontSize: 12)),
                  selected: sel,
                  onSelected: (_) =>
                      ref.read(selectedCategoryProvider.notifier).state = cat,
                  visualDensity: VisualDensity.compact,
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 56,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No products yet',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to add your first product',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.15,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: products.length,
                    itemBuilder: (ctx, i) => _ProductCard(product: products[i]),
                  ),
          ),
          if (cart.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
                      child: Row(
                        children: [
                          Text(
                            'Cart (${cart.length})',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            'Rp ${total.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: (cart.length * 48.0 + 4).clamp(0, 180),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: cart.length,
                        itemBuilder: (ctx, i) => _CartRow(item: cart[i]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                      child: FilledButton.icon(
                        onPressed: () => context.push('/checkout'),
                        icon: const Icon(
                          Icons.shopping_cart_checkout,
                          size: 20,
                        ),
                        label: Text('Checkout'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (s, i) => s + (i.price * i.quantity));
});

class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ref
              .read(cartProvider.notifier)
              .addItem(
                CartItem(
                  productId: product.id,
                  productName: product.name,
                  price: product.price,
                ),
              );
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} added'),
              duration: const Duration(milliseconds: 400),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onLongPress: () => _showProductActions(context, ref, product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child:
                  product.imagePath != null &&
                      ImageService.fileExists(product.imagePath)
                  ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                  : Container(
                      color: colors.primaryContainer.withValues(alpha: 0.35),
                      child: Center(
                        child: Text(
                          product.name.isNotEmpty
                              ? product.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colors.onPrimaryContainer.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Rp ${product.price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartRow extends ConsumerWidget {
  final CartItem item;
  const _CartRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${item.quantity}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.productName,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              size: 20,
              color: Colors.redAccent,
            ),
            onPressed: () => ref
                .read(cartProvider.notifier)
                .updateQuantity(item.productId, item.quantity - 1),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              size: 20,
              color: Colors.green,
            ),
            onPressed: () => ref
                .read(cartProvider.notifier)
                .updateQuantity(item.productId, item.quantity + 1),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

void _showProductActions(BuildContext context, WidgetRef ref, Product product) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Product'),
            onTap: () {
              Navigator.pop(ctx);
              _showProductForm(context, ref, product: product);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.visibility_off_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Disable',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () {
              Navigator.pop(ctx);
              ref.read(menuNotifierProvider.notifier).toggleActive(product.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(ctx);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dctx) => AlertDialog(
                  title: const Text('Delete Product'),
                  content: Text('Permanently remove "${product.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(dctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                ref
                    .read(menuNotifierProvider.notifier)
                    .deleteProduct(product.id);
              }
            },
          ),
        ],
      ),
    ),
  );
}

void _showProductForm(BuildContext context, WidgetRef ref, {Product? product}) {
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
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 800,
                          );
                          if (picked != null) {
                            final path = await ImageService.savePickedImage(
                              picked.path,
                            );
                            setSheetState(() {
                              imagePath = path;
                            });
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child:
                              imagePath != null &&
                                  ImageService.fileExists(imagePath)
                              ? Image.file(File(imagePath!), fit: BoxFit.cover)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 28,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    Text(
                                      'Photo',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        prefixIcon: Icon(Icons.fastfood_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceCtrl,
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
                        return n == null || n <= 0 ? 'Invalid price' : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (!useCustom && cats.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        children: [
                          ...cats.map(
                            (c) => ChoiceChip(
                              label: Text(
                                c.name,
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: selCat == c.name,
                              onSelected: (_) => setSheetState(() {
                                selCat = c.name;
                                customCatCtrl.clear();
                              }),
                              visualDensity: VisualDensity.compact,
                              showCheckmark: false,
                            ),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.edit, size: 14),
                            label: const Text(
                              'Custom',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () =>
                                setSheetState(() => useCustom = true),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
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
                        onPressed: () => setSheetState(() => useCustom = false),
                      ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final name = nameCtrl.text.trim();
                        final price =
                            double.tryParse(priceCtrl.text.trim()) ?? 0;
                        final cat = useCustom
                            ? customCatCtrl.text.trim()
                            : (selCat ?? '');
                        if (isEdit) {
                          await ref
                              .read(menuNotifierProvider.notifier)
                              .updateProduct(
                                product.copyWith(
                                  name: name,
                                  price: price,
                                  category: cat,
                                  imagePath: imagePath,
                                  clearImage: imagePath == null,
                                ),
                              );
                        } else {
                          await ref
                              .read(menuNotifierProvider.notifier)
                              .addProduct(
                                name: name,
                                price: price,
                                category: cat,
                                imagePath: imagePath,
                              );
                        }
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: Text(isEdit ? 'Update' : 'Add Product'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  ).then((_) {
    nameCtrl.dispose();
    priceCtrl.dispose();
    customCatCtrl.dispose();
  });
}

void _showCategorySheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        final cats = ref.watch(categoryListProvider);

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Manage Categories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...cats.map(
                  (cat) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      child: Text(
                        cat.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    title: Text(cat.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () async {
                            final ctrl = TextEditingController(text: cat.name);
                            final result = await showDialog<String>(
                              context: ctx,
                              builder: (dctx) => AlertDialog(
                                title: const Text('Rename Category'),
                                content: TextField(
                                  controller: ctrl,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    hintText: 'New name',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dctx),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(dctx, ctrl.text),
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            );
                            if (result != null && result.trim().isNotEmpty) {
                              ref
                                  .read(categoryNotifierProvider.notifier)
                                  .update(cat.copyWith(name: result.trim()));
                              setSheetState(() {});
                            }
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: ctx,
                              builder: (dctx) => AlertDialog(
                                title: const Text('Delete Category'),
                                content: Text('Remove "${cat.name}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => Navigator.pop(dctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              ref
                                  .read(categoryNotifierProvider.notifier)
                                  .delete(cat.id);
                              setSheetState(() {});
                            }
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    final ctrl = TextEditingController();
                    final result = await showDialog<String>(
                      context: ctx,
                      builder: (dctx) => AlertDialog(
                        title: const Text('New Category'),
                        content: TextField(
                          controller: ctrl,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Category name',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dctx),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(dctx, ctrl.text.trim()),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                    if (result != null && result.isNotEmpty) {
                      ref.read(categoryNotifierProvider.notifier).add(result);
                      setSheetState(() {});
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Category'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    ),
  );
}
