import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/formatters.dart';
import '../data/receipt_printer.dart';
import '../data/store_settings.dart';
import '../domain/sale.dart';
import 'printer_sheet.dart';
import 'store_settings_dialog.dart';

Future<void> showReceiptDialog(
  BuildContext context,
  Sale sale, {
  double? paidAmount,
  double? changeAmount,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ReceiptDialog(
      sale: sale,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
    ),
  );
}

class ReceiptDialog extends ConsumerWidget {
  const ReceiptDialog({
    required this.sale,
    this.paidAmount,
    this.changeAmount,
    super.key,
  });

  final Sale sale;
  final double? paidAmount;
  final double? changeAmount;

  void _copyToClipboard(BuildContext context, WidgetRef ref) {
    final printer = ref.read(receiptPrinterProvider);
    final receiptText = printer.formatReceiptText(
      sale,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
    );
    Clipboard.setData(ClipboardData(text: receiptText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Teks struk disalin! Siap dikirim via WhatsApp/SMS.'),
          ],
        ),
        backgroundColor: Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _printViaCable(BuildContext context, WidgetRef ref) {
    try {
      ref.read(receiptPrinterProvider).printViaBrowser(
            sale,
            paidAmount: paidAmount,
            changeAmount: changeAmount,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Perintah cetak dikirim ke printer thermal kabel USB!'),
            ],
          ),
          backgroundColor: Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencetak: $e'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final store = ref.watch(storeSettingsProvider);

    final finalPaid = paidAmount ?? sale.totalAmount;
    final finalChange = changeAmount ?? (finalPaid - sale.totalAmount);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      title: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaksi Berhasil',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                Text(
                  'Struk #${sale.id} · ${formatDateTime(sale.createdAt)}',
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20),
            tooltip: 'Ubah Data Toko & Struk',
            onPressed: () => showStoreSettingsDialog(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Realistic thermal paper card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Store Header
                    Text(
                      store.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceMono(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (store.address.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          store.address,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.black54),
                        ),
                      ),
                    if (store.phone.isNotEmpty)
                      Text(
                        'Telp: ${store.phone}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.black54),
                      ),
                    const SizedBox(height: 10),
                    _ReceiptDashedLine(),
                    const SizedBox(height: 8),

                    // Meta Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('No: #${sale.id}', style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.black87)),
                        Text(formatDateTime(sale.createdAt), style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.black87)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kasir: ${sale.cashierName ?? 'Staff'}', style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.black87)),
                        Text('Plg: ${sale.buyerName ?? 'Umum'}', style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ReceiptDashedLine(),
                    const SizedBox(height: 8),

                    // Items list
                    for (final item in sale.items) ...[
                      Text(
                        item.productName,
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '  ${item.quantity} x ${formatRupiah(item.sellingPrice)}',
                              style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.black87),
                            ),
                            Text(
                              formatRupiah(item.subtotal),
                              style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                    _ReceiptDashedLine(),
                    const SizedBox(height: 8),

                    // Totals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL',
                          style: GoogleFonts.spaceMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          formatRupiah(sale.totalAmount),
                          style: GoogleFonts.spaceMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    if (paidAmount != null && paidAmount! > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tunai', style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.black87)),
                          Text(formatRupiah(finalPaid), style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.black87)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Kembalian', style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.black87)),
                          Text(
                            formatRupiah(finalChange < 0 ? 0 : finalChange),
                            style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    _ReceiptDashedLine(),
                    const SizedBox(height: 10),

                    // Footer notes
                    for (final line in store.footerNote.split('\n'))
                      if (line.trim().isNotEmpty)
                        Text(
                          line.trim(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.black54),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: () => _copyToClipboard(context, ref),
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Salin Teks'),
        ),
        OutlinedButton.icon(
          onPressed: () => showPrinterSheet(
            context,
            sale,
            paidAmount: finalPaid,
            changeAmount: finalChange,
          ),
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text('Opsi Printer'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
          ),
          onPressed: () => _printViaCable(context, ref),
          icon: const Icon(Icons.cable_rounded, size: 18),
          label: const Text('Cetak Struk (Kabel USB)'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}

class _ReceiptDashedLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey)),
            );
          }),
        );
      },
    );
  }
}
