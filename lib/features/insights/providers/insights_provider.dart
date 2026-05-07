// lib/features/insights/providers/insights_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database_service.dart';
import '../../../models/product.dart';
import '../../../models/transaction.dart';

final transactionVersionProvider = StateProvider<int>((ref) => 0);

void invalidateInsights(WidgetRef ref) {
  ref.read(transactionVersionProvider.notifier).state++;
}

final _dbProvider = Provider((ref) => ref.read(databaseServiceProvider));

final _transactionsProvider = Provider<List<Transaction>>((ref) {
  ref.watch(transactionVersionProvider);
  return ref.read(_dbProvider).transactions;
});

final _productsMapProvider = Provider<Map<String, Product>>((ref) {
  ref.watch(transactionVersionProvider);
  return ref.read(_dbProvider).productsMap;
});

class PopularProduct {
  final Product product;
  final int orderCount;
  final double trend;

  const PopularProduct({
    required this.product,
    required this.orderCount,
    required this.trend,
  });
}

final popularProductsProvider = Provider<List<PopularProduct>>((ref) {
  ref.watch(transactionVersionProvider);

  final now = DateTime.now();
  final thisMonthStart = DateTime(now.year, now.month, 1);
  final lastMonthStart = DateTime(now.year, now.month - 1, 1);

  final transactions = ref.read(_transactionsProvider);
  final products = ref.read(_productsMapProvider);

  final thisMonthCounts = <String, int>{};
  final lastMonthCounts = <String, int>{};

  for (final txn in transactions) {
    final isThisMonth = txn.timestamp.isAfter(thisMonthStart);
    final isLastMonth =
        txn.timestamp.isAfter(lastMonthStart) &&
        txn.timestamp.isBefore(thisMonthStart);

    for (final item in txn.items) {
      if (isThisMonth) {
        thisMonthCounts[item.productId] =
            (thisMonthCounts[item.productId] ?? 0) + item.quantity;
      }
      if (isLastMonth) {
        lastMonthCounts[item.productId] =
            (lastMonthCounts[item.productId] ?? 0) + item.quantity;
      }
    }
  }

  final sorted = thisMonthCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.take(5).map((entry) {
    final lastCount = lastMonthCounts[entry.key] ?? 0;
    final trend = lastCount > 0
        ? ((entry.value - lastCount) / lastCount) * 100
        : 100.0;
    final product =
        products[entry.key] ??
        Product(id: entry.key, name: 'Unknown', price: 0);
    return PopularProduct(
      product: product,
      orderCount: entry.value,
      trend: trend,
    );
  }).toList();
});

final pairingMapProvider = Provider<Map<String, List<String>>>((ref) {
  ref.watch(transactionVersionProvider);

  final transactions = ref.read(_transactionsProvider);
  final coOccurrence = <String, Map<String, int>>{};

  for (final txn in transactions) {
    final productIds = txn.items.map((e) => e.productId).toSet().toList();
    for (var i = 0; i < productIds.length; i++) {
      coOccurrence.putIfAbsent(productIds[i], () => {});
      for (var j = i + 1; j < productIds.length; j++) {
        coOccurrence[productIds[i]]!.update(
          productIds[j],
          (v) => v + 1,
          ifAbsent: () => 1,
        );
        coOccurrence.putIfAbsent(productIds[j], () => {});
        coOccurrence[productIds[j]]!.update(
          productIds[i],
          (v) => v + 1,
          ifAbsent: () => 1,
        );
      }
    }
  }

  final result = <String, List<String>>{};
  for (final entry in coOccurrence.entries) {
    final sorted = entry.value.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    result[entry.key] = sorted.map((e) => e.key).toList();
  }

  return result;
});

class DailyStats {
  final int orderCount;
  final double revenue;
  final String topProductName;

  const DailyStats({
    required this.orderCount,
    required this.revenue,
    required this.topProductName,
  });
}

class DailyStatsData {
  final DailyStats today;
  final DailyStats yesterday;

  const DailyStatsData({required this.today, required this.yesterday});
}

final dailyStatsProvider = Provider<DailyStatsData>((ref) {
  ref.watch(transactionVersionProvider);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final yesterdayStart = todayStart.subtract(const Duration(days: 1));
  final yesterdayEnd = todayStart;

  final transactions = ref.read(_transactionsProvider);
  final products = ref.read(_productsMapProvider);

  DailyStats calc(DateTime dayStart, DateTime dayEnd) {
    double revenue = 0;
    final itemCounts = <String, int>{};

    final dayTxns = transactions
        .where(
          (t) => t.timestamp.isAfter(dayStart) && t.timestamp.isBefore(dayEnd),
        )
        .toList();

    for (final txn in dayTxns) {
      revenue += txn.totalAmount;
      for (final item in txn.items) {
        itemCounts[item.productId] =
            (itemCounts[item.productId] ?? 0) + item.quantity;
      }
    }

    String topName = '-';
    int maxCount = 0;
    for (final entry in itemCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        topName = products[entry.key]?.name ?? '-';
      }
    }

    return DailyStats(
      orderCount: dayTxns.length,
      revenue: revenue,
      topProductName: topName,
    );
  }

  return DailyStatsData(
    today: calc(todayStart, DateTime.now()),
    yesterday: calc(yesterdayStart, yesterdayEnd),
  );
});

class HourlyCount {
  final int hour;
  final int count;

  const HourlyCount({required this.hour, required this.count});
}

final busyHoursProvider = Provider<List<HourlyCount>>((ref) {
  ref.watch(transactionVersionProvider);

  final start = DateTime.now().subtract(const Duration(days: 30));
  final transactions = ref.read(_transactionsProvider);
  final counts = List.filled(24, 0);

  for (final txn in transactions) {
    if (txn.timestamp.isAfter(start)) {
      counts[txn.timestamp.hour]++;
    }
  }

  return List.generate(24, (i) => HourlyCount(hour: i, count: counts[i]));
});

class CustomerInsight {
  final String customerName;
  final int orderCount;
  final double totalSpent;
  final List<String> usualItems;

  const CustomerInsight({
    required this.customerName,
    required this.orderCount,
    required this.totalSpent,
    required this.usualItems,
  });
}

final customerInsightsProvider = Provider<Map<String, CustomerInsight>>((ref) {
  ref.watch(transactionVersionProvider);

  final transactions = ref.read(_transactionsProvider);
  final products = ref.read(_productsMapProvider);

  final customerTxns = <String, List<Transaction>>{};
  for (final txn in transactions) {
    if (txn.customerName.isEmpty) continue;
    customerTxns.putIfAbsent(txn.customerName, () => []).add(txn);
  }

  final result = <String, CustomerInsight>{};

  for (final entry in customerTxns.entries) {
    if (entry.value.length < 3) continue;

    double totalSpent = 0;
    final itemFreq = <String, int>{};

    for (final txn in entry.value) {
      totalSpent += txn.totalAmount;
      for (final item in txn.items) {
        itemFreq[item.productId] =
            (itemFreq[item.productId] ?? 0) + item.quantity;
      }
    }

    final sorted = itemFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final usualItems = sorted
        .take(3)
        .map((e) => products[e.key]?.name ?? '-')
        .toList();

    result[entry.key] = CustomerInsight(
      customerName: entry.key,
      orderCount: entry.value.length,
      totalSpent: totalSpent,
      usualItems: usualItems,
    );
  }

  return result;
});
