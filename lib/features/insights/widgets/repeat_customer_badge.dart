// lib/features/insights/widgets/repeat_customer_badge.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/insights_provider.dart';

class RepeatCustomerBadge extends ConsumerWidget {
  final String customerName;

  const RepeatCustomerBadge({super.key, required this.customerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (customerName.isEmpty) return const SizedBox.shrink();

    final insights = ref.watch(customerInsightsProvider);
    final customer = insights[customerName];

    if (customer == null) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.stars_rounded, color: colors.onTertiaryContainer),
                const SizedBox(width: 6),
                Text(
                  'Repeat Customer',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${customer.orderCount} orders \u00B7 \$${customer.totalSpent.toStringAsFixed(2)} total',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onTertiaryContainer,
              ),
            ),
            if (customer.usualItems.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Usual: ${customer.usualItems.join(", ")}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onTertiaryContainer.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
