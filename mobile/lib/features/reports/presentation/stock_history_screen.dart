import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/formatters.dart';
import '../../auth/presentation/user_menu.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product.dart';
import '../data/report_repository.dart';

class StockHistoryScreen extends ConsumerStatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  ConsumerState<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends ConsumerState<StockHistoryScreen> {
  Product? _product;
  String? _referenceType;
  int _page = 1;
  Future<List<StockHistoryEntry>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = ref.read(reportRepositoryProvider).stockHistory(
            productId: _product?.id,
            referenceType: _referenceType,
            page: _page,
          );
    });
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'sale': return Icons.point_of_sale_rounded;
      case 'purchase': return Icons.shopping_cart_checkout_rounded;
      case 'adjustment': return Icons.tune_rounded;
      default: return Icons.history_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'sale': return Colors.blue.shade600;
      case 'purchase': return Colors.green.shade600;
      case 'adjustment': return Colors.orange.shade600;
      default: return Colors.grey;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'sale': return 'Penjualan';
      case 'purchase': return 'Pembelian';
      case 'adjustment': return 'Penyesuaian';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.history_rounded, color: scheme.primary),
            const SizedBox(width: 8),
            Text('Riwayat Stok', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: const <Widget>[UserMenu()],
      ),
      body: Column(
        children: <Widget>[
          // Filter bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            color: scheme.surfaceContainerLow,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: productsAsync.when(
                    data: (products) => DropdownButtonFormField<Product?>(
                      initialValue: _product,
                      decoration: const InputDecoration(
                        labelText: 'Produk',
                        isDense: true,
                        prefixIcon: Icon(Icons.inventory_2_outlined, size: 18),
                      ),
                      items: <DropdownMenuItem<Product?>>[
                        const DropdownMenuItem<Product?>(value: null, child: Text('Semua produk')),
                        for (final p in products)
                          DropdownMenuItem<Product?>(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (p) {
                        setState(() { _product = p; _page = 1; });
                        _load();
                      },
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _referenceType,
                    decoration: const InputDecoration(
                      labelText: 'Tipe',
                      isDense: true,
                      prefixIcon: Icon(Icons.filter_list_rounded, size: 18),
                    ),
                    items: const <DropdownMenuItem<String?>>[
                      DropdownMenuItem<String?>(value: null, child: Text('Semua tipe')),
                      DropdownMenuItem<String?>(value: 'sale', child: Text('Penjualan')),
                      DropdownMenuItem<String?>(value: 'purchase', child: Text('Pembelian')),
                      DropdownMenuItem<String?>(value: 'adjustment', child: Text('Penyesuaian')),
                    ],
                    onChanged: (v) {
                      setState(() { _referenceType = v; _page = 1; });
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: FutureBuilder<List<StockHistoryEntry>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
                        const SizedBox(height: 8),
                        Text('Gagal memuat data', style: TextStyle(color: scheme.error)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  );
                }
                final items = snapshot.data ?? const <StockHistoryEntry>[];
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('Tidak ada riwayat.', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final h = items[index];
                    final change = h.quantityChange;
                    final isPositive = change >= 0;
                    final typeColor = _typeColor(h.referenceType);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_typeIcon(h.referenceType), color: typeColor, size: 22),
                      ),
                      title: Text(
                        h.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _typeLabel(h.referenceType),
                                  style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formatDateTime(DateTime.parse(h.createdAt)),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          if ((h.adjustmentReason ?? '').isNotEmpty || (h.adjustmentDescription ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                [h.adjustmentReason, h.adjustmentDescription].where((s) => s != null && s.isNotEmpty).join(' · '),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${change > 0 ? '+' : ''}$change',
                              style: TextStyle(
                                color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('stok ${h.finalStock}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Pagination
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  onPressed: _page > 1 ? () { setState(() => _page--); _load(); } : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Sebelumnya',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Hal. $_page',
                    style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary),
                  ),
                ),
                IconButton(
                  onPressed: () { setState(() => _page++); _load(); },
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Berikutnya',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
