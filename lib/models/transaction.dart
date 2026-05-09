// lib/models/transaction.dart
class Transaction {
  final String id;
  final DateTime timestamp;
  final double totalAmount;
  final String paymentMethod;
  final String customerName;
  final List<TransactionItem> items;

  const Transaction({
    required this.id,
    required this.timestamp,
    required this.totalAmount,
    this.paymentMethod = 'cash',
    this.customerName = '',
    this.items = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'totalAmount': totalAmount,
    'paymentMethod': paymentMethod,
    'customerName': customerName,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    paymentMethod: json['paymentMethod'] as String? ?? 'cash',
    customerName: json['customerName'] as String? ?? '',
    items:
        (json['items'] as List<dynamic>?)
            ?.map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

class TransactionItem {
  final String id;
  final String transactionId;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String customNotes;
  final List<String> selectedAddOnIds;

  const TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    this.productName = '',
    required this.quantity,
    required this.price,
    this.customNotes = '',
    this.selectedAddOnIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'transactionId': transactionId,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'price': price,
    'customNotes': customNotes,
    'selectedAddOnIds': selectedAddOnIds,
  };

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      TransactionItem(
        id: json['id'] as String,
        transactionId: json['transactionId'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String? ?? '',
        quantity: (json['quantity'] as num).toInt(),
        price: (json['price'] as num).toDouble(),
        customNotes: json['customNotes'] as String? ?? '',
        selectedAddOnIds:
            (json['selectedAddOnIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}
