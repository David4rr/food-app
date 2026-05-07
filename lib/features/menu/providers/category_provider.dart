// lib/features/menu/providers/category_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/database_service.dart';
import '../../../models/category.dart';

final categoryListProvider = Provider<List<ProductCategory>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(databaseServiceProvider).categories;
});

final categoryNamesProvider = Provider<Set<String>>((ref) {
  ref.watch(dataVersionProvider);
  return ref
      .watch(databaseServiceProvider)
      .categories
      .map((c) => c.name)
      .toSet();
});

class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final _uuid = const Uuid();

  CategoryNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> add(String name) async {
    await _ref
        .read(databaseServiceProvider)
        .addCategory(ProductCategory(id: _uuid.v4(), name: name));
    _ref.read(dataVersionProvider.notifier).state++;
  }

  Future<void> update(ProductCategory category) async {
    await _ref.read(databaseServiceProvider).updateCategory(category);
    _ref.read(dataVersionProvider.notifier).state++;
  }

  Future<void> delete(String id) async {
    await _ref.read(databaseServiceProvider).deleteCategory(id);
    _ref.read(dataVersionProvider.notifier).state++;
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<void>>((ref) {
      return CategoryNotifier(ref);
    });
