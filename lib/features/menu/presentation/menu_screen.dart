// lib/features/menu/presentation/menu_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/product.dart';
import '../providers/menu_provider.dart';
import 'product_form_screen.dart';
import 'category_screen.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(filteredProductsProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Manage Categories',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CategoryScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final cat = categories[index];
                final selected = cat == selectedCat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) =>
                      ref.read(selectedCategoryProvider.notifier).state = cat,
                  visualDensity: VisualDensity.compact,
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 64,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No products yet',
                          style: Theme.of(context).textTheme.bodyLarge
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: products.length,
                    itemBuilder: (ctx, index) =>
                        _ProductGridCard(product: products[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product saved'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProductGridCard extends ConsumerWidget {
  final Product product;
  const _ProductGridCard({required this.product});

  void _showProductActions(BuildContext context, WidgetRef ref) {
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductFormScreen(product: product),
                  ),
                );
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
                ref
                    .read(menuNotifierProvider.notifier)
                    .toggleActive(product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product disabled'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => ProductFormScreen(product: product),
            ),
          );
        },
        onLongPress: () => _showProductActions(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: product.imagePath != null
                  ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                  : Container(
                      color: colors.primaryContainer.withValues(alpha: 0.4),
                      child: Center(
                        child: Text(
                          product.name.isNotEmpty
                              ? product.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colors.onPrimaryContainer.withValues(
                              alpha: 0.6,
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
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Rp ${product.price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
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
