// lib/models/product.dart
class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final bool isActive;
  final int totalOrdered;
  final String? imagePath;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.category = '',
    this.isActive = true,
    this.totalOrdered = 0,
    this.imagePath,
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
    bool? isActive,
    int? totalOrdered,
    String? imagePath,
    bool clearImage = false,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      totalOrdered: totalOrdered ?? this.totalOrdered,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'category': category,
    'isActive': isActive,
    'totalOrdered': totalOrdered,
    'imagePath': imagePath,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    category: json['category'] as String? ?? '',
    isActive: json['isActive'] as bool? ?? true,
    totalOrdered: (json['totalOrdered'] as num?)?.toInt() ?? 0,
    imagePath: json['imagePath'] as String?,
  );
}
