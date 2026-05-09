class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final bool isActive;
  final int totalOrdered;
  final String? imagePath;
  final List<AddOn> addOns;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.category = '',
    this.isActive = true,
    this.totalOrdered = 0,
    this.imagePath,
    this.addOns = const [],
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
    List<AddOn>? addOns,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      totalOrdered: totalOrdered ?? this.totalOrdered,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      addOns: addOns ?? this.addOns,
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
    'addOns': addOns.map((e) => e.toJson()).toList(),
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    category: json['category'] as String? ?? '',
    isActive: json['isActive'] as bool? ?? true,
    totalOrdered: (json['totalOrdered'] as num?)?.toInt() ?? 0,
    imagePath: json['imagePath'] as String?,
    addOns:
        (json['addOns'] as List<dynamic>?)
            ?.map((e) => AddOn.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

class AddOn {
  final String id;
  final String name;
  final double price;

  const AddOn({required this.id, required this.name, this.price = 0});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price};

  factory AddOn.fromJson(Map<String, dynamic> json) => AddOn(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num?)?.toDouble() ?? 0,
  );
}
