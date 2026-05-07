import 'package:flutter_test/flutter_test.dart';

import 'package:food_app/features/insights/providers/insights_provider.dart';
import 'package:food_app/models/product.dart';

void main() {
  test('HourlyCount creates correctly', () {
    const hc = HourlyCount(hour: 14, count: 5);
    expect(hc.hour, 14);
    expect(hc.count, 5);
  });

  test('DailyStats creates correctly', () {
    const ds = DailyStats(
      orderCount: 10,
      revenue: 150.5,
      topProductName: 'Cake',
    );
    expect(ds.orderCount, 10);
    expect(ds.revenue, 150.5);
    expect(ds.topProductName, 'Cake');
  });

  test('PopularProduct creates correctly', () {
    final p = PopularProduct(
      product: const Product(id: '1', name: 'Cake', price: 10),
      orderCount: 5,
      trend: 25.0,
    );
    expect(p.orderCount, 5);
    expect(p.trend, 25.0);
  });
}
