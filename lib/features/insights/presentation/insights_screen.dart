// lib/features/insights/presentation/insights_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/popular_products_widget.dart';
import '../widgets/daily_stats_bar.dart';
import '../widgets/busy_hours_chart.dart';
import '../providers/insights_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/export_service.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(_transactionCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        centerTitle: true,
        actions: [
          if (txns > 0)
            PopupMenuButton<String>(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Export Report',
              onSelected: (action) {
                final allTxns = ref.read(databaseServiceProvider).transactions;
                if (action == 'csv') {
                  ExportService.exportTransactionsCsv(allTxns);
                } else if (action == 'pdf') {
                  ExportService.exportReportPdf(allTxns);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'csv',
                  child: ListTile(
                    leading: Icon(Icons.table_chart),
                    title: Text('Export CSV'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf),
                    title: Text('Export PDF Report'),
                    dense: true,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: txns == 0
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insights_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No transaction data yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Insights will appear after first sale',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                DailyStatsBar(),
                SizedBox(height: 12),
                PopularProductsWidget(),
                SizedBox(height: 12),
                BusyHoursChart(),
                SizedBox(height: 80),
              ],
            ),
    );
  }
}

final _transactionCountProvider = Provider<int>((ref) {
  ref.watch(transactionVersionProvider);
  return ref.read(databaseServiceProvider).transactions.length;
});
