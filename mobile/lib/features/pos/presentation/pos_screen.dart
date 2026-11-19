import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_content.dart';
import '../../auth/presentation/user_menu.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product.dart';
import '../domain/cart.dart';
import 'cart_sheet.dart';
import 'pos_controller.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  int? _selectedCategory;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Product> _visibleProducts(List<Product> products) {
    var filtered = products;
    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.categoryId == _selectedCategory).toList();
    }
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return filtered;
    return filtered
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            (p.categoryName?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  void _addToCart(Product product) {
    final message = ref.read(posControllerProvider.notifier).add(product);
    if (message != null && mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(posControllerProvider);
    final products = ref.watch(productListProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.point_of_sale_rounded, color: scheme.primary, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'BN Mart · Kasir',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'Ganti ke Mode Terang (Light)'
                : 'Ganti ke Mode Gelap (Dark)',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
          ),
          const UserMenu(),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Cari produk atau kategori...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: AsyncContent<List<Product>>(
              value: products,
              onRetry: () => ref.invalidate(productListProvider),
              builder: (list) {
                final visible = _visibleProducts(list);
                if (visible.isEmpty) {
                  return const EmptyState(
                    message: 'Tidak ada produk yang cocok.',
                    icon: Icons.search_off_rounded,
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth <= 0) {
                      return const SizedBox.shrink();
                    }
                    final width = constraints.maxWidth;
                    final int columns;
                    final double ratio;
                    if (width < 360) {
                      columns = 2;
                      ratio = 0.88;
                    } else if (width < 600) {
                      columns = 2;
                      ratio = 0.95;
                    } else if (width < 900) {
                      columns = 3;
                      ratio = 1.1;
                    } else {
                      columns = (width / 220).floor().clamp(3, 6);
                      ratio = 1.15;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: ratio,
                      ),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final product = visible[index];
                        final inCart = cart.lineFor(product.id)?.quantity ?? 0;
                        return _ProductCard(
                          product: product,
                          inCart: inCart,
                          onTap: () => _addToCart(product),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _CartBar(cart: cart),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.inCart, required this.onTap});

  final Product product;
  final int inCart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final disabled = product.isOutOfStock;

    return Card(
      color: disabled
          ? (isDark ? const Color(0xFF131A15) : scheme.surfaceContainerHighest)
          : inCart > 0
              ? (isDark ? const Color(0xFF1E3A25) : const Color(0xFFE8F5E9))
              : (isDark ? const Color(0xFF18231B) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: inCart > 0
              ? scheme.primary
              : (isDark ? const Color(0xFF2E4032) : scheme.outlineVariant),
          width: inCart > 0 ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: disabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: disabled
                            ? scheme.onSurfaceVariant
                            : (isDark ? Colors.white : scheme.onSurface),
                      ),
                    ),
                  ),
                  if (inCart > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2E7D32) : scheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$inCart',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (product.categoryName != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF213B28) : scheme.secondaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.categoryName!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFA7E8B4) : scheme.onSecondaryContainer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Text(
                    formatRupiah(product.sellingPrice),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: disabled
                          ? scheme.onSurfaceVariant
                          : (isDark ? const Color(0xFF4ADE80) : scheme.primary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        disabled ? Icons.remove_shopping_cart_outlined : Icons.inventory_2_outlined,
                        size: 13,
                        color: disabled ? scheme.error : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          disabled ? 'Stok habis' : 'Stok ${product.currentStock}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: disabled ? scheme.error : scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF141C16) : Colors.white,
      elevation: 12,
      shadowColor: Colors.black45,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF213B28) : scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shopping_cart_rounded,
                      color: isDark ? const Color(0xFF4ADE80) : scheme.primary,
                      size: 22,
                    ),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${cart.itemCount} item dipilih',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      formatRupiah(cart.total),
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF2E7D32) : scheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: cart.isEmpty ? null : () => showCartSheet(context),
                icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                label: Text(
                  'Checkout',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
