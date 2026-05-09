import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/product.dart';
import '../../../menu/providers/menu_provider.dart';
import 'product_form_sheet.dart';

void showProductActionsSheet(
  BuildContext context,
  WidgetRef ref,
  Product product,
) {
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
              showProductFormSheet(context, ref, product);
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
