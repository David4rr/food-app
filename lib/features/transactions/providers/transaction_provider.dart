// lib/features/transactions/providers/transaction_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database_service.dart';
import '../../../models/transaction.dart';
import '../../insights/providers/insights_provider.dart';

final transactionSearchProvider = StateProvider<String>((ref) => '');
final transactionDateFilterProvider = StateProvider<DateTimeRange?>(
  (ref) => null,
);

final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  ref.watch(transactionVersionProvider);
  final db = ref.watch(databaseServiceProvider);
  final query = ref.watch(transactionSearchProvider).toLowerCase();
  final dateRange = ref.watch(transactionDateFilterProvider);

  var txns = db.transactions.toList();

  if (dateRange != null) {
    txns = txns
        .where(
          (t) =>
              t.timestamp.isAfter(dateRange.start) &&
              t.timestamp.isBefore(dateRange.end.add(const Duration(days: 1))),
        )
        .toList();
  }

  if (query.isNotEmpty) {
    txns = txns
        .where(
          (t) =>
              t.customerName.toLowerCase().contains(query) ||
              t.id.contains(query) ||
              t.items.any((i) => i.productName.toLowerCase().contains(query)),
        )
        .toList();
  }

  txns.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return txns;
});

final transactionByIdProvider = Provider.family<Transaction?, String>((
  ref,
  id,
) {
  ref.watch(transactionVersionProvider);
  final db = ref.watch(databaseServiceProvider);
  try {
    return db.transactions.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
});
