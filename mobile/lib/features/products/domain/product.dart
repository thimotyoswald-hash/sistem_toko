class Category {
  const Category({required this.id, required this.name});

  final int id;
  final String name;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: (json['id'] as num).toInt(), name: json['name'] as String);
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.currentStock,
    this.categoryName,
  });

  final int id;
  final String name;
  final int categoryId;
  final String? categoryName;
  final double purchasePrice;
  final double sellingPrice;
  final int currentStock;

  bool get isOutOfStock => currentStock <= 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    return Product(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      categoryId: (json['category_id'] as num).toInt(),
      categoryName: category is Map ? category['name'] as String? : null,
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      currentStock: (json['current_stock'] as num).toInt(),
    );
  }

  static List<Product> listFromPayload(Map<String, dynamic> payload) {
    final rows = payload['data'];
    if (rows is! List) {
      return const <Product>[];
    }
    return rows
        .whereType<Map>()
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}
