import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/image_service.dart';
import '../../../../models/product.dart';
import '../../providers/checkout_provider.dart';

void showAddToCartSheet(BuildContext context, WidgetRef ref, Product product) {
  final notesCtrl = TextEditingController();
  final addOns = product.addOns;
  final selectedIds = <String>{};
  int qty = 1;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        final colors = Theme.of(context).colorScheme;
        final addOnsWithPrice = addOns.where((a) => a.price > 0).toList();
        final addOnsFree = addOns.where((a) => a.price == 0).toList();
        final addOnsTotal = selectedIds.fold<double>(
          0,
          (s, id) => s + (addOns.firstWhere((a) => a.id == id).price),
        );
        final itemTotal = (product.price + addOnsTotal) * qty;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (product.imagePath != null &&
                          ImageService.fileExists(product.imagePath))
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(product.imagePath!),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Rp ${product.price.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (addOns.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Add-ons',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (addOnsFree.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        children: addOnsFree
                            .map(
                              (a) => FilterChip(
                                label: Text(
                                  a.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: selectedIds.contains(a.id),
                                onSelected: (v) => setSheetState(() {
                                  if (v) {
                                    selectedIds.add(a.id);
                                  } else {
                                    selectedIds.remove(a.id);
                                  }
                                }),
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                    if (addOnsWithPrice.isNotEmpty) ...[
                      if (addOnsFree.isNotEmpty) const SizedBox(height: 4),
                      ...addOnsWithPrice.map(
                        (a) => CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          title: Text(
                            a.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            '+Rp ${a.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.primary,
                            ),
                          ),
                          value: selectedIds.contains(a.id),
                          onChanged: (v) => setSheetState(() {
                            if (v == true) {
                              selectedIds.add(a.id);
                            } else {
                              selectedIds.remove(a.id);
                            }
                          }),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'e.g. No spicy, less sugar...',
                      prefixIcon: Icon(Icons.note_outlined, size: 20),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Qty',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton.filled(
                        onPressed: qty > 1
                            ? () => setSheetState(() => qty--)
                            : null,
                        icon: const Icon(Icons.remove, size: 18),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$qty',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () => setSheetState(() => qty++),
                        icon: const Icon(Icons.add, size: 18),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(cartProvider.notifier)
                          .addItem(
                            CartItem(
                              productId: product.id,
                              productName: product.name,
                              price: product.price,
                              quantity: qty,
                              notes: notesCtrl.text.trim(),
                              selectedAddOnIds: selectedIds.toList(),
                              addOnsTotal: addOnsTotal,
                            ),
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$qty× ${product.name} added'),
                          duration: const Duration(milliseconds: 600),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 20),
                    label: Text(
                      'Add to Cart - Rp ${itemTotal.toStringAsFixed(0)}',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
