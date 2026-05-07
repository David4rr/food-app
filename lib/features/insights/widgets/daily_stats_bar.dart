// lib/features/insights/widgets/daily_stats_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/insights_provider.dart';

class DailyStatsBar extends ConsumerWidget {
  const DailyStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dailyStatsProvider);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Today',
                orders: stats.today.orderCount,
                revenue: stats.today.revenue,
                topItem: stats.today.topProductName,
                colors: colors,
                textTheme: textTheme,
              ),
            ),
            Container(width: 1, height: 64, color: colors.outlineVariant),
            Expanded(
              child: _StatTile(
                label: 'Yesterday',
                orders: stats.yesterday.orderCount,
                revenue: stats.yesterday.revenue,
                topItem: stats.yesterday.topProductName,
                colors: colors,
                textTheme: textTheme,
                isYesterday: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int orders;
  final double revenue;
  final String topItem;
  final ColorScheme colors;
  final TextTheme textTheme;
  final bool isYesterday;

  const _StatTile({
    required this.label,
    required this.orders,
    required this.revenue,
    required this.topItem,
    required this.colors,
    required this.textTheme,
    this.isYesterday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: isYesterday ? colors.onSurfaceVariant : colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text('$orders orders', style: textTheme.titleMedium),
        Text(
          '\$${revenue.toStringAsFixed(2)}',
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          topItem,
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
