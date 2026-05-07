// lib/features/menu/providers/category_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/database_service.dart';
import '../../../models/category.dart';

final categoryListProvider = Provider<List<ProductCategory>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.categories;
});

final categoryNamesProvider = Provider<Set<String>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.categories.map((c) => c.name).toSet();
});

class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final _uuid = const Uuid();

  CategoryNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> add(String name) async {
    final db = _ref.read(databaseServiceProvider);
    await db.addCategory(ProductCategory(id: _uuid.v4(), name: name));
  }

  Future<void> update(ProductCategory category) async {
    await _ref.read(databaseServiceProvider).updateCategory(category);
  }

  Future<void> delete(String id) async {
    await _ref.read(databaseServiceProvider).deleteCategory(id);
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<void>>((ref) {
      return CategoryNotifier(ref);
    });
