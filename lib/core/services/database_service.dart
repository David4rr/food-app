// lib/core/services/database_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/product.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('Override with initialized instance');
});

final dataVersionProvider = StateProvider<int>((ref) => 0);

class DatabaseService extends ChangeNotifier {
  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  List<Transaction> _transactions = [];
  late final String _dirPath;

  DatabaseService._();

  static Future<DatabaseService> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final service = DatabaseService._();
    service._dirPath = dir.path;
    await service._load();
    return service;
  }

  List<Product> get products => _products;
  List<ProductCategory> get categories => _categories;
  List<Transaction> get transactions => _transactions;

  Map<String, Product> get productsMap => {for (final p in _products) p.id: p};
  Map<String, ProductCategory> get categoriesMap => {
    for (final c in _categories) c.id: c,
  };

  Product? getProduct(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addProduct(Product product) async {
    _products.add(product);
    await _saveAndNotify();
  }

  Future<void> updateProduct(Product product) async {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      _products[idx] = product;
      await _saveAndNotify();
    }
  }

  Future<void> addCategory(ProductCategory category) async {
    _categories.add(category);
    await _saveAndNotify();
  }

  Future<void> updateCategory(ProductCategory category) async {
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx >= 0) {
      _categories[idx] = category;
      await _saveAndNotify();
    }
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    await _saveAndNotify();
  }

  Future<void> addTransaction(Transaction transaction) async {
    _transactions.add(transaction);
    await _saveAndNotify();
  }

  Future<void> _saveAndNotify() async {
    await _save();
    notifyListeners();
  }

  Future<void> seedDemoData() async {
    if (_categories.isNotEmpty || _products.isNotEmpty) return;

    _categories.addAll([
      const ProductCategory(id: 'cat-1', name: 'Makanan'),
      const ProductCategory(id: 'cat-2', name: 'Minuman'),
      const ProductCategory(id: 'cat-3', name: 'Cemilan'),
      const ProductCategory(id: 'cat-4', name: 'Dessert'),
    ]);

    _products.addAll([
      Product(
        id: 'seed-1',
        name: 'Nasi Goreng',
        price: 15.0,
        category: 'Makanan',
      ),
      Product(
        id: 'seed-2',
        name: 'Mie Goreng',
        price: 12.0,
        category: 'Makanan',
      ),
      Product(
        id: 'seed-3',
        name: 'Ayam Geprek',
        price: 18.0,
        category: 'Makanan',
      ),
      Product(
        id: 'seed-4',
        name: 'Es Teh Manis',
        price: 5.0,
        category: 'Minuman',
      ),
      Product(id: 'seed-5', name: 'Es Jeruk', price: 7.0, category: 'Minuman'),
      Product(
        id: 'seed-6',
        name: 'Kopi Susu',
        price: 10.0,
        category: 'Minuman',
      ),
      Product(
        id: 'seed-7',
        name: 'Pisang Goreng',
        price: 8.0,
        category: 'Cemilan',
      ),
      Product(
        id: 'seed-8',
        name: 'Tahu Crispy',
        price: 8.0,
        category: 'Cemilan',
      ),
      Product(
        id: 'seed-9',
        name: 'Sate Ayam',
        price: 20.0,
        category: 'Makanan',
      ),
      Product(
        id: 'seed-10',
        name: 'Bakso Urat',
        price: 14.0,
        category: 'Makanan',
      ),
      Product(id: 'seed-11', name: 'Sop Iga', price: 25.0, category: 'Makanan'),
      Product(
        id: 'seed-12',
        name: 'Teh Tarik',
        price: 8.0,
        category: 'Minuman',
      ),
    ]);

    await _saveAndNotify();
  }

  Future<void> _load() async {
    final catFile = File('$_dirPath/categories.json');
    final prodFile = File('$_dirPath/products.json');
    final txnFile = File('$_dirPath/transactions.json');

    if (await catFile.exists()) {
      final json = jsonDecode(await catFile.readAsString()) as List<dynamic>;
      _categories = json
          .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (await prodFile.exists()) {
      final json = jsonDecode(await prodFile.readAsString()) as List<dynamic>;
      _products = json
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (await txnFile.exists()) {
      final json = jsonDecode(await txnFile.readAsString()) as List<dynamic>;
      _transactions = json
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _save() async {
    await File(
      '$_dirPath/categories.json',
    ).writeAsString(jsonEncode(_categories.map((e) => e.toJson()).toList()));
    await File(
      '$_dirPath/products.json',
    ).writeAsString(jsonEncode(_products.map((e) => e.toJson()).toList()));
    await File(
      '$_dirPath/transactions.json',
    ).writeAsString(jsonEncode(_transactions.map((e) => e.toJson()).toList()));
  }
}
