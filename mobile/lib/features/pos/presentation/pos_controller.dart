import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product.dart';
import '../data/sale_repository.dart';
import '../domain/cart.dart';
import '../domain/sale.dart';

final NotifierProvider<PosController, Cart> posControllerProvider =
    NotifierProvider<PosController, Cart>(PosController.new);

class PosController extends Notifier<Cart> {
  @override
  Cart build() => const Cart();

  /// Adds [product] and returns a message when the cart refused the addition,
  /// so the screen can surface the stock limit the cashier just hit.
  String? add(Product product, {int quantity = 1}) {
    if (product.currentStock <= 0) {
      return 'Stok ${product.name} habis.';
    }

    final existing = state.lineFor(product.id);
    final currentQuantity = existing?.quantity ?? 0;
    final nextQuantity = currentQuantity + quantity;

    if (nextQuantity > product.currentStock) {
      return 'Stok ${product.name} hanya tersisa ${product.currentStock}.';
    }

    final lines = <CartLine>[...state.lines];
    if (existing == null) {
      lines.add(CartLine(product: product, quantity: quantity));
    } else {
      lines[lines.indexWhere((line) => line.product.id == product.id)] = existing.withQuantity(
        nextQuantity,
      );
    }

    state = state.copyWith(lines: lines);
    return null;
  }

  void decrement(int productId) {
    final line = state.lineFor(productId);
    if (line == null) {
      return;
    }
    if (line.quantity <= 1) {
      remove(productId);
      return;
    }

    final lines = <CartLine>[...state.lines];
    lines[lines.indexWhere((entry) => entry.product.id == productId)] = line.withQuantity(
      line.quantity - 1,
    );
    state = state.copyWith(lines: lines);
  }

  void remove(int productId) {
    state = state.copyWith(
      lines: state.lines.where((line) => line.product.id != productId).toList(),
    );
  }

  void setBuyer(Buyer? buyer) {
    state = state.copyWith(buyer: buyer, clearBuyer: buyer == null);
  }

  void clear() {
    state = const Cart();
  }

  /// Sends the cart to the server, which recomputes prices and stock.
  Future<Sale> checkout() async {
    final cart = state;
    if (cart.isEmpty) {
      throw const ApiException('Keranjang masih kosong.');
    }

    final sale = await ref.read(saleRepositoryProvider).create(
      buyerId: cart.buyer?.id,
      items: cart.lines
          .map((line) => (productId: line.product.id, quantity: line.quantity))
          .toList(),
    );

    state = const Cart();
    ref.invalidate(productListProvider);
    ref.invalidate(productsProvider);
    return sale;
  }
}
