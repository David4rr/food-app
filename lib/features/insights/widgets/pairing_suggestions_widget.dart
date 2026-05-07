// lib/features/insights/widgets/pairing_suggestions_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/product.dart';
import '../../../core/services/database_service.dart';
import '../providers/insights_provider.dart';

class PairingSuggestionsWidget extends ConsumerWidget {
  final String productId;

  const PairingSuggestionsWidget({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairingMap = ref.watch(pairingMapProvider);
    final pairIds = pairingMap[productId] ?? [];
    final top2 = pairIds.take(2).toList();

    if (top2.isEmpty) return const SizedBox.shrink();

    final db = ref.read(databaseServiceProvider);
    final products = top2
        .map((id) => db.getProduct(id))
        .whereType<Product>()
        .toList();

    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: colors.primary),
                const SizedBox(width: 6),
                Text(
                  'Frequently Ordered Together',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...products.map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(p.name),
                    const Spacer(),
                    Text(
                      '\$${p.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
