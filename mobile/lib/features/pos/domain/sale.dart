import '../../../core/utils/formatters.dart';

class SaleItem {
  const SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sellingPrice,
    required this.subtotal,
  });

  final int productId;
  final String productName;
  final int quantity;
  final double sellingPrice;
  final double subtotal;

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      productId: (json['product_id'] as num).toInt(),
      productName: json['product_name'] as String? ?? 'Produk',
      quantity: (json['quantity'] as num).toInt(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}

class Sale {
  const Sale({
    required this.id,
    required this.totalAmount,
    required this.items,
    required this.createdAt,
    this.buyerName,
    this.cashierName,
  });

  final int id;
  final double totalAmount;
  final List<SaleItem> items;
  final DateTime createdAt;
  final String? buyerName;
  final String? cashierName;

  factory Sale.fromJson(Map<String, dynamic> json) {
    final buyer = json['buyer'];
    final items = json['items'];
    return Sale(
      id: (json['id'] as num).toInt(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      buyerName: buyer is Map ? buyer['name'] as String? : null,
      cashierName: json['cashier'] as String?,
      createdAt: parseApiDate(json['created_at']),
      items: items is List
          ? items
                .whereType<Map>()
                .map((row) => SaleItem.fromJson(Map<String, dynamic>.from(row)))
                .toList()
          : const <SaleItem>[],
    );
  }
}
