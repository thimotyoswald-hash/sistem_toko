import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers.dart';
import '../../auth/presentation/user_menu.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product.dart';

const List<String> _types = <String>['rusak', 'expired', 'lainnya'];
const Map<String, IconData> _typeIcons = {
  'rusak': Icons.broken_image_outlined,
  'expired': Icons.hourglass_disabled_rounded,
  'lainnya': Icons.more_horiz_rounded,
};
const Map<String, Color> _typeColors = {
  'rusak': Colors.red,
  'expired': Colors.orange,
  'lainnya': Colors.grey,
};

class StockAdjustmentScreen extends ConsumerStatefulWidget {
  const StockAdjustmentScreen({super.key});

  @override
  ConsumerState<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends ConsumerState<StockAdjustmentScreen> {
  Product? _product;
  String _type = _types.first;
  final TextEditingController _qty = TextEditingController(text: '1');
  final TextEditingController _desc = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _qty.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_product == null) {
      setState(() => _error = 'Pilih produk.');
      return;
    }
    final qty = int.tryParse(_qty.text);
    if (qty == null || qty < 1) {
      setState(() => _error = 'Jumlah minimal 1.');
      return;
    }
    if (qty > _product!.currentStock) {
      setState(() => _error = 'Jumlah ($qty) melebihi sisa stok produk (${_product!.currentStock}).');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final client = ref.read(apiClientProvider);
      await client.postJson(
        '/stock-adjustments',
        body: <String, dynamic>{
          'product_id': _product!.id,
          'type': _type,
          'quantity': qty,
          if (_desc.text.trim().isNotEmpty) 'description': _desc.text.trim(),
        },
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
                Text('Stok keluar berhasil dicatat.'),
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        setState(() { _product = null; _qty.text = '1'; _desc.clear(); });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
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
            Icon(Icons.remove_circle_rounded, color: scheme.error),
            const SizedBox(width: 8),
            Text('Stok Keluar', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: const <Widget>[UserMenu()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: scheme.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Catat produk yang keluar karena rusak, kadaluarsa, atau sebab lain. Stok akan dikurangi secara otomatis.',
                      style: TextStyle(fontSize: 12, color: scheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Detail Stok Keluar', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            // Produk
            productsAsync.when(
              data: (products) => DropdownButtonFormField<Product>(
                initialValue: _product,
                decoration: InputDecoration(
                  labelText: 'Pilih Produk',
                  prefixIcon: Icon(Icons.inventory_2_outlined, color: scheme.primary),
                ),
                items: <DropdownMenuItem<Product>>[
                  for (final p in products)
                    DropdownMenuItem<Product>(
                      value: p,
                      child: Text('${p.name} (stok ${p.currentStock})'),
                    ),
                ],
                onChanged: (p) => setState(() => _product = p),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Gagal memuat produk: $e'),
            ),
            if (_product != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_rounded, size: 16, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Stok saat ini: ${_product!.currentStock}',
                      style: TextStyle(fontSize: 13, color: scheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Alasan - dengan chip selector
            Text('Alasan Keluar', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _types.map((t) {
                final selected = _type == t;
                final color = _typeColors[t] ?? Colors.grey;
                return ChoiceChip(
                  selected: selected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_typeIcons[t], size: 16, color: selected ? Colors.white : color),
                      const SizedBox(width: 6),
                      Text(t.substring(0, 1).toUpperCase() + t.substring(1)),
                    ],
                  ),
                  onSelected: (v) { if (v) setState(() => _type = t); },
                  selectedColor: color,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : color,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Jumlah
            TextField(
              controller: _qty,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah',
                prefixIcon: Icon(Icons.numbers_rounded, color: scheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            // Catatan
            TextField(
              controller: _desc,
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.note_alt_outlined, color: scheme.primary),
                hintText: 'Tambahkan keterangan jika perlu...',
              ),
              maxLines: 3,
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 10),
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
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: scheme.error),
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Menyimpan...' : 'Simpan Stok Keluar'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
