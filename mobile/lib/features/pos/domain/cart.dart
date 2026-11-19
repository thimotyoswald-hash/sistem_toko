import '../../products/domain/product.dart';

class Buyer {
  const Buyer({required this.id, required this.name, this.phone});

  final int id;
  final String name;
  final String? phone;

  factory Buyer.fromJson(Map<String, dynamic> json) {
    return Buyer(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get subtotal => product.sellingPrice * quantity;

  CartLine withQuantity(int newQuantity) => CartLine(product: product, quantity: newQuantity);
}

/// The cashier's in-progress sale. Prices come from the product row the server
/// sent, and the server recomputes the real total again on checkout.
class Cart {
  const Cart({this.lines = const <CartLine>[], this.buyer});

  final List<CartLine> lines;
  final Buyer? buyer;

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;

  int get itemCount => lines.fold(0, (total, line) => total + line.quantity);

  double get total => lines.fold(0, (total, line) => total + line.subtotal);

  CartLine? lineFor(int productId) {
    for (final line in lines) {
      if (line.product.id == productId) {
        return line;
      }
    }
    return null;
  }

  Cart copyWith({List<CartLine>? lines, Buyer? buyer, bool clearBuyer = false}) {
    return Cart(
      lines: lines ?? this.lines,
      buyer: clearBuyer ? null : (buyer ?? this.buyer),
    );
  }
}
