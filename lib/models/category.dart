// lib/models/category.dart
class ProductCategory {
  final String id;
  final String name;

  const ProductCategory({required this.id, required this.name});

  ProductCategory copyWith({String? id, String? name}) {
    return ProductCategory(id: id ?? this.id, name: name ?? this.name);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
