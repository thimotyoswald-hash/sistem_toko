import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_content.dart';
import '../../auth/presentation/user_menu.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';

class ProductManageScreen extends ConsumerStatefulWidget {
  const ProductManageScreen({super.key});

  @override
  ConsumerState<ProductManageScreen> createState() => _ProductManageScreenState();
}

class _ProductManageScreenState extends ConsumerState<ProductManageScreen> {
  final TextEditingController _search = TextEditingController();
  int? _categoryId;
  int _page = 1;
  String? _searchQuery;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    ref.invalidate(productsProvider);
    ref.invalidate(productListProvider);
  }

  Future<void> _openForm({Product? product}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ProductFormDialog(product: product),
    );
    if (saved == true) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      productsProvider(
        ProductQuery(
          page: _page,
          search: _searchQuery,
          categoryId: _categoryId,
        ),
      ),
    );
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
        actions: const <Widget>[UserMenu()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Cari nama produk',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _search.clear();
                                setState(() {
                                  _searchQuery = null;
                                  _page = 1;
                                });
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (value) => setState(() {
                      _searchQuery = value.trim().isEmpty ? null : value.trim();
                      _page = 1;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                categoriesAsync.when(
                  data: (cats) => DropdownButton<int?>(
                    value: _categoryId,
                    hint: const Text('Kategori'),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(value: null, child: Text('Semua')),
                      for (final c in cats)
                        DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() {
                      _categoryId = v;
                      _page = 1;
                    }),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncContent<List<Product>>(
              value: productsAsync,
              onRetry: _reload,
              builder: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('Belum ada produk.'));
                }
                return ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final scheme = Theme.of(context).colorScheme;
                    final isLowStock = p.currentStock <= 5 && p.currentStock > 0;
                    final isOutOfStock = p.currentStock == 0;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? scheme.errorContainer
                              : isLowStock
                                  ? Colors.orange.shade100
                                  : scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: isOutOfStock
                              ? scheme.error
                              : isLowStock
                                  ? Colors.orange.shade700
                                  : scheme.primary,
                          size: 22,
                        ),
                      ),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Row(
                        children: [
                          if (p.categoryName != null)
                            Container(
                              margin: const EdgeInsets.only(right: 6, top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: scheme.secondaryContainer.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.categoryName!,
                                style: TextStyle(fontSize: 10, color: scheme.onSecondaryContainer),
                              ),
                            ),
                          Text(
                            isOutOfStock ? 'Stok habis' : 'Stok ${p.currentStock}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOutOfStock ? scheme.error : isLowStock ? Colors.orange.shade700 : scheme.onSurfaceVariant,
                              fontWeight: isOutOfStock || isLowStock ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatRupiah(p.sellingPrice),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            onPressed: () => _openForm(product: p),
                            tooltip: 'Edit produk',
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _Pagination(
            page: _page,
            hasData: productsAsync.hasValue && (productsAsync.value?.isNotEmpty ?? false),
            onPrev: () => setState(() => _page = _page > 1 ? _page - 1 : 1),
            onNext: () => setState(() => _page++),
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.hasData,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final bool hasData;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextButton(onPressed: page > 1 ? onPrev : null, child: const Text('Sebelum')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Halaman $page'),
          ),
          TextButton(onPressed: hasData ? onNext : null, child: const Text('Berikut')),
        ],
      ),
    );
  }
}

class _ProductFormDialog extends ConsumerStatefulWidget {
  const _ProductFormDialog({this.product});

  final Product? product;

  @override
  ConsumerState<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _purchasePrice;
  late final TextEditingController _sellingPrice;
  late final TextEditingController _stock;
  int? _categoryId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _purchasePrice = TextEditingController(text: p == null ? '' : p.purchasePrice.toString());
    _sellingPrice = TextEditingController(text: p == null ? '' : p.sellingPrice.toString());
    _stock = TextEditingController(text: p == null ? '0' : p.currentStock.toString());
    _categoryId = p?.categoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _purchasePrice.dispose();
    _sellingPrice.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(productRepositoryProvider);
      final purchasePrice = double.parse(_purchasePrice.text.replaceAll(',', '.'));
      final sellingPrice = double.parse(_sellingPrice.text.replaceAll(',', '.'));
      final stock = int.parse(_stock.text);

      if (widget.product == null) {
        await repo.create(
          categoryId: _categoryId!,
          name: _name.text.trim(),
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          currentStock: stock,
        );
      } else {
        await repo.update(
          widget.product!.id,
          categoryId: _categoryId!,
          name: _name.text.trim(),
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          currentStock: stock,
        );
      }
      ref.invalidate(productListProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return AlertDialog(
      title: Text(widget.product == null ? 'Tambah produk' : 'Ubah produk'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 10),
                categoriesAsync.when(
                  data: (cats) => DropdownButtonFormField<int>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: <DropdownMenuItem<int>>[
                      for (final c in cats)
                        DropdownMenuItem<int>(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                    validator: (v) => v == null ? 'Pilih kategori' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Gagal memuat kategori: $e'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _purchasePrice,
                  decoration: const InputDecoration(labelText: 'Harga beli (Rp)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final val = double.tryParse(v?.replaceAll(',', '.') ?? '');
                    if (val == null) return 'Masukkan angka yang valid';
                    if (val < 0) return 'Harga tidak boleh negatif';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _sellingPrice,
                  decoration: const InputDecoration(labelText: 'Harga jual (Rp)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final val = double.tryParse(v?.replaceAll(',', '.') ?? '');
                    if (val == null) return 'Masukkan angka yang valid';
                    if (val < 0) return 'Harga tidak boleh negatif';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _stock,
                  decoration: const InputDecoration(labelText: 'Stok saat ini'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final val = int.tryParse(v ?? '');
                    if (val == null) return 'Masukkan angka bulat yang valid';
                    if (val < 0) return 'Stok tidak boleh negatif';
                    return null;
                  },
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Batal')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
