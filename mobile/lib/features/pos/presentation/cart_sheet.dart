import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../data/sale_repository.dart';
import '../domain/cart.dart';
import 'pos_controller.dart';
import 'receipt_sheet.dart';

Future<void> showCartSheet(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width > 650) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
          child: const CartSheet(),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const CartSheet(),
  );
}

class CartSheet extends ConsumerStatefulWidget {
  const CartSheet({super.key});

  @override
  ConsumerState<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<CartSheet> {
  final TextEditingController _cashController = TextEditingController();
  bool _busy = false;
  String? _error;
  double _cashTendered = 0;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _setCash(double amount) {
    setState(() {
      _cashTendered = amount;
      _cashController.text = amount.round().toString();
    });
  }

  Future<void> _checkout() async {
    final cart = ref.read(posControllerProvider);
    final total = cart.total;
    final paid = _cashTendered > 0 ? _cashTendered : total;

    if (paid < total) {
      setState(() => _error = 'Nominal pembayaran kurang dari total belanja.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final sale = await ref.read(posControllerProvider.notifier).checkout();
      if (!mounted) return;

      final change = paid - total;
      Navigator.of(context).pop();
      await showReceiptDialog(
        context,
        sale,
        paidAmount: paid,
        changeAmount: change,
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Transaksi gagal: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _addBuyer() async {
    final created = await showDialog<Buyer>(
      context: context,
      builder: (_) => const _NewBuyerDialog(),
    );
    if (created != null) {
      ref.read(posControllerProvider.notifier).setBuyer(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(posControllerProvider);
    final controller = ref.read(posControllerProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = cart.total;
    final change = _cashTendered > 0 ? (_cashTendered - total) : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: <Widget>[
                  Icon(Icons.shopping_bag_outlined, color: scheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Keranjang Belanja',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cart.itemCount} item',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: cart.isEmpty ? null : controller.clear,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Kosongkan'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (cart.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text('Keranjang masih kosong.', style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: cart.lines.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final line = cart.lines[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  line.product.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${formatRupiah(line.product.sellingPrice)} / pcs',
                                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Kurangi',
                                  onPressed: () => controller.decrement(line.product.id),
                                  icon: const Icon(Icons.remove, size: 18),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    '${line.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Tambah',
                                  onPressed: () {
                                    final message = controller.add(line.product);
                                    if (message != null) {
                                      ScaffoldMessenger.of(context)
                                        ..clearSnackBars()
                                        ..showSnackBar(SnackBar(content: Text(message)));
                                    }
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 80,
                            child: Text(
                              formatRupiah(line.subtotal),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const Divider(height: 1),
            // Checkout & Payment details
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _BuyerPicker(
                      buyer: cart.buyer,
                      onChanged: controller.setBuyer,
                      onAddBuyer: _addBuyer,
                    ),
                    const SizedBox(height: 12),
                    // Total belanja
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Total Belanja', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                          formatRupiah(total),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Pembayaran Tunai & Kembalian
                    if (cart.isNotEmpty) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cashController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Uang Diterima (Tunai)',
                                prefixText: 'Rp ',
                                isDense: true,
                              ),
                              onChanged: (val) {
                                final digitsOnly = val.replaceAll(RegExp(r'[^0-9]'), '');
                                final parsed = double.tryParse(digitsOnly) ?? 0;
                                setState(() => _cashTendered = parsed);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.tonal(
                            onPressed: () => _setCash(total),
                            child: const Text('Uang Pas'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Quick Cash Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final amt in [10000.0, 20000.0, 50000.0, 100000.0])
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  label: Text(formatRupiah(amt)),
                                  onPressed: () => _setCash(amt),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Kembalian status
                      if (_cashTendered > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: change >= 0
                                ? const Color(0xFF1B5E20).withValues(alpha: 0.1)
                                : scheme.errorContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                change >= 0 ? 'Kembalian' : 'Kurang',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: change >= 0 ? const Color(0xFF1B5E20) : scheme.error,
                                ),
                              ),
                              Text(
                                formatRupiah(change.abs()),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: change >= 0 ? const Color(0xFF1B5E20) : scheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: scheme.error, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: (_busy || cart.isEmpty) ? null : _checkout,
                      icon: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(_busy ? 'Menyimpan Transaksi...' : 'Selesaikan Transaksi & Buat Struk'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyerPicker extends ConsumerWidget {
  const _BuyerPicker({required this.buyer, required this.onChanged, required this.onAddBuyer});

  final Buyer? buyer;
  final ValueChanged<Buyer?> onChanged;
  final VoidCallback onAddBuyer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buyers = ref.watch(buyerListProvider);

    return Row(
      children: <Widget>[
        Expanded(
          child: buyers.when(
            loading: () => DropdownButtonFormField<int?>(
              items: const [],
              onChanged: null,
              decoration: const InputDecoration(
                labelText: 'Memuat data pelanggan...',
                prefixIcon: SizedBox(
                  width: 18,
                  height: 18,
                  child: Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
              ),
            ),
            error: (_, _) => const Text('Daftar pembeli gagal dimuat.'),
            data: (list) {
              final selected = list.any((entry) => entry.id == buyer?.id) ? buyer?.id : null;
              return DropdownButtonFormField<int?>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Pelanggan / Pembeli',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(value: null, child: Text('Umum (Non-Member)')),
                  ...list.map(
                    (entry) => DropdownMenuItem<int?>(
                      value: entry.id,
                      child: Text(entry.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    onChanged(null);
                    return;
                  }
                  onChanged(list.firstWhere((entry) => entry.id == value));
                },
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Tambah Pembeli Baru',
          onPressed: onAddBuyer,
          icon: const Icon(Icons.person_add_alt_1_rounded),
        ),
      ],
    );
  }
}

class _NewBuyerDialog extends ConsumerStatefulWidget {
  const _NewBuyerDialog();

  @override
  ConsumerState<_NewBuyerDialog> createState() => _NewBuyerDialogState();
}

class _NewBuyerDialogState extends ConsumerState<_NewBuyerDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Nama pembeli wajib diisi.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final buyer = await ref
          .read(saleRepositoryProvider)
          .createBuyer(name: _name.text.trim(), phone: _phone.text.trim());
      ref.invalidate(buyerListProvider);
      if (mounted) {
        Navigator.of(context).pop(buyer);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Pelanggan Baru'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'No. WhatsApp / Telepon (opsional)',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
