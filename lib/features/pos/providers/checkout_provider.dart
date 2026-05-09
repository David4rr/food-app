import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/database_service.dart';
import '../../../models/transaction.dart';
import '../../insights/providers/insights_provider.dart';

final isProcessingProvider = StateProvider<bool>((ref) => false);

class CartItem {
  final String productId;
  final String productName;
  final double price;
  int quantity;
  String notes;
  List<String> selectedAddOnIds;
  double addOnsTotal;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.quantity = 1,
    this.notes = '',
    this.selectedAddOnIds = const [],
    this.addOnsTotal = 0,
  });
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem item) {
    final index = state.indexWhere((e) => e.productId == item.productId);
    if (index >= 0) {
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == index)
            CartItem(
              productId: state[i].productId,
              productName: state[i].productName,
              price: state[i].price,
              quantity: state[i].quantity + 1,
              notes: state[i].notes,
              selectedAddOnIds: state[i].selectedAddOnIds,
              addOnsTotal: state[i].addOnsTotal,
            )
          else
            state[i],
      ];
    } else {
      state = [...state, item];
    }
  }

  void removeItem(String productId) {
    state = state.where((e) => e.productId != productId).toList();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.productId == productId)
          CartItem(
            productId: item.productId,
            productName: item.productName,
            price: item.price,
            quantity: quantity,
            notes: item.notes,
            selectedAddOnIds: item.selectedAddOnIds,
            addOnsTotal: item.addOnsTotal,
          )
        else
          item,
    ];
  }

  void clear() => state = [];

  double get total =>
      state.fold(0, (sum, i) => sum + (i.price + i.addOnsTotal) * i.quantity);
}

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (s, i) => s + (i.price + i.addOnsTotal) * i.quantity);
});

final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, AsyncValue<void>>((ref) {
      return CheckoutNotifier(ref);
    });

class CheckoutNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final _uuid = const Uuid();

  CheckoutNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> checkout({
    required String customerName,
    required String paymentMethod,
  }) async {
    final cart = _ref.read(cartProvider);
    if (cart.isEmpty) return;

    state = const AsyncValue.loading();

    try {
      final db = _ref.read(databaseServiceProvider);
      final total = _ref.read(cartProvider.notifier).total;
      final txnId = _uuid.v4();

      final items = cart
          .map(
            (c) => TransactionItem(
              id: _uuid.v4(),
              transactionId: txnId,
              productId: c.productId,
              productName: c.productName,
              quantity: c.quantity,
              price: c.price,
              customNotes: c.notes,
              selectedAddOnIds: c.selectedAddOnIds,
            ),
          )
          .toList();

      final transaction = Transaction(
        id: txnId,
        timestamp: DateTime.now(),
        totalAmount: total,
        paymentMethod: paymentMethod,
        customerName: customerName,
        items: items,
      );

      await db.addTransaction(transaction);

      for (final cartItem in cart) {
        final product = db.getProduct(cartItem.productId);
        if (product != null) {
          await db.updateProduct(
            product.copyWith(
              totalOrdered: product.totalOrdered + cartItem.quantity,
            ),
          );
        }
      }

      _ref.read(cartProvider.notifier).clear();
      _ref.read(transactionVersionProvider.notifier).state++;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
