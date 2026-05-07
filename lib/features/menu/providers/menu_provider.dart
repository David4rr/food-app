// lib/features/menu/providers/menu_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/database_service.dart';
import '../../../models/product.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final categoriesProvider = Provider<List<String>>((ref) {
  ref.watch(dataVersionProvider);
  final cats =
      ref.watch(databaseServiceProvider).categories.map((c) => c.name).toList()
        ..sort();
  return ['All', ...cats];
});

final filteredProductsProvider = Provider<List<Product>>((ref) {
  ref.watch(dataVersionProvider);
  final db = ref.watch(databaseServiceProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final category = ref.watch(selectedCategoryProvider);

  var products = db.products.where((p) => p.isActive).toList();

  if (category != 'All') {
    products = products.where((p) => p.category == category).toList();
  }
  if (query.isNotEmpty) {
    products = products
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();
  }

  products.sort((a, b) => a.name.compareTo(b.name));
  return products;
});

final productByIdProvider = Provider.family<Product?, String>((ref, id) {
  ref.watch(dataVersionProvider);
  final db = ref.watch(databaseServiceProvider);
  return db.getProduct(id);
});

class MenuNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final _uuid = const Uuid();

  MenuNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> addProduct({
    required String name,
    required double price,
    required String category,
    String? imagePath,
  }) async {
    final db = _ref.read(databaseServiceProvider);
    final product = Product(
      id: _uuid.v4(),
      name: name,
      price: price,
      category: category,
      imagePath: imagePath,
    );
    await db.addProduct(product);
    _ref.read(dataVersionProvider.notifier).state++;
  }

  Future<void> updateProduct(Product product) async {
    final db = _ref.read(databaseServiceProvider);
    await db.updateProduct(product);
    _ref.read(dataVersionProvider.notifier).state++;
  }

  Future<void> toggleActive(String productId) async {
    final db = _ref.read(databaseServiceProvider);
    final product = db.getProduct(productId);
    if (product != null) {
      await db.updateProduct(product.copyWith(isActive: !product.isActive));
      _ref.read(dataVersionProvider.notifier).state++;
    }
  }

  Future<void> deleteProduct(String productId) async {
    final db = _ref.read(databaseServiceProvider);
    final product = db.getProduct(productId);
    if (product != null) {
      await db.updateProduct(product.copyWith(isActive: false));
      _ref.read(dataVersionProvider.notifier).state++;
    }
  }
}

final menuNotifierProvider =
    StateNotifierProvider<MenuNotifier, AsyncValue<void>>((ref) {
      return MenuNotifier(ref);
    });
