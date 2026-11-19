import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/formatters.dart';
import '../../auth/presentation/user_menu.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product.dart';
import '../data/distributor_repository.dart';
import '../data/purchase_repository.dart';

class PurchaseScreen extends ConsumerStatefulWidget {
  const PurchaseScreen({super.key});

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseRow {
  _PurchaseRow({required this.product})
      : qtyController = TextEditingController(text: '1'),
        priceController = TextEditingController(text: product.purchasePrice.toString());

  final Product product;
  final TextEditingController qtyController;
  final TextEditingController priceController;

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }

  int get quantity => int.tryParse(qtyController.text) ?? 0;
  double get price => double.tryParse(priceController.text) ?? 0;
  double get subtotal => quantity * price;
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen> {
  int? _distributorId;
  final List<_PurchaseRow> _rows = <_PurchaseRow>[];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final r in _rows) { r.dispose(); }
    super.dispose();
  }

  void _addProduct(int productId) {
    final productsState = ref.read(productListProvider);
    final product = productsState.when(
      data: (list) => list.firstWhere((prod) => prod.id == productId),
      loading: () => null,
      error: (_, __) => null,
    );
    if (product == null) return;
    final exists = _rows.any((r) => r.product.id == product.id);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk sudah ada di daftar.')),
      );
      return;
    }
    setState(() => _rows.add(_PurchaseRow(product: product)));
  }

  void _removeRow(int index) {
    final row = _rows.removeAt(index);
    row.dispose();
    setState(() {});
  }

  double get _grandTotal => _rows.fold<double>(0, (s, r) => s + r.subtotal);

  Future<void> _submit() async {
    if (_distributorId == null) {
      setState(() => _error = 'Pilih distributor terlebih dahulu.');
      return;
    }
    if (_rows.isEmpty) {
      setState(() => _error = 'Tambahkan minimal satu produk.');
      return;
    }
    for (final r in _rows) {
      if (r.quantity <= 0) {
        setState(() => _error = 'Jumlah untuk ${r.product.name} harus minimal 1.');
        return;
      }
      if (r.price < 0) {
        setState(() => _error = 'Harga beli untuk ${r.product.name} tidak boleh negatif.');
        return;
      }
    }
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(purchaseRepositoryProvider).create(
            distributorId: _distributorId!,
            items: _rows
                .map((r) => <String, dynamic>{
                      'product_id': r.product.id,
                      'quantity': r.quantity,
                      'purchase_price': r.price,
                    })
                .toList(),
          );
      ref.invalidate(productListProvider);
      ref.invalidate(productsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Pembelian berhasil disimpan!'),
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        setState(() {
          for (final r in _rows) { r.dispose(); }
          _rows.clear();
          _distributorId = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final distributorsAsync = ref.watch(distributorListProvider);
    final productsAsync = ref.watch(productListProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_cart_checkout_rounded, color: scheme.primary),
            const SizedBox(width: 8),
            Text('Pembelian', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: const <Widget>[UserMenu()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Distributor
                  Text('Distributor', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  distributorsAsync.when(
                    data: (dists) => DropdownButtonFormField<int>(
                      initialValue: _distributorId,
                      decoration: InputDecoration(
                        labelText: 'Pilih Distributor',
                        prefixIcon: Icon(Icons.local_shipping_outlined, color: scheme.primary),
                      ),
                      items: <DropdownMenuItem<int>>[
                        for (final d in dists) DropdownMenuItem<int>(value: d.id, child: Text(d.name)),
                      ],
                      onChanged: (v) => setState(() => _distributorId = v),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Gagal memuat distributor: $e', style: TextStyle(color: scheme.error)),
                  ),
                  const SizedBox(height: 20),
                  // Tambah Produk
                  Text('Daftar Produk', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  productsAsync.when(
                    data: (products) => DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Tambah Produk',
                        prefixIcon: Icon(Icons.add_box_outlined, color: scheme.primary),
                        hintText: 'Pilih produk untuk ditambahkan',
                      ),
                      initialValue: null,
                      items: <DropdownMenuItem<int>>[
                        for (final p in products)
                          DropdownMenuItem<int>(value: p.id, child: Text('${p.name} (stok: ${p.currentStock})')),
                      ],
                      onChanged: (p) { if (p != null) _addProduct(p); },
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Gagal memuat produk: $e', style: TextStyle(color: scheme.error)),
                  ),
                  const SizedBox(height: 16),
                  if (_rows.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.outlineVariant, style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 36, color: scheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text('Belum ada produk dipilih', style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  else
                    ...List.generate(_rows.length, (index) {
                      final row = _rows[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    row.product.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error, size: 20),
                                  onPressed: () => _removeRow(index),
                                  tooltip: 'Hapus',
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: row.qtyController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Qty',
                                      isDense: true,
                                      prefixIcon: Icon(Icons.numbers_rounded, size: 18),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: row.priceController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Harga Beli',
                                      isDense: true,
                                      prefixIcon: Icon(Icons.attach_money_rounded, size: 18),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Subtotal: ${formatRupiah(row.subtotal)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: scheme.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Bottom action bar
          if (_rows.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: scheme.surface,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Pembelian', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                        Text(
                          formatRupiah(_grandTotal),
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: scheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(_saving ? 'Menyimpan...' : 'Simpan Pembelian'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
