import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

import '../../../core/utils/formatters.dart';
import '../domain/sale.dart';
import 'receipt_web_printer.dart';
import 'store_settings.dart';

final Provider<ReceiptPrinter> receiptPrinterProvider = Provider<ReceiptPrinter>(
  (ref) {
    final settings = ref.watch(storeSettingsProvider);
    return ReceiptPrinter(
      storeSettings: settings,
      paperSize: settings.paperSizeMm == 80 ? PaperSize.mm80 : PaperSize.mm58,
    );
  },
);

/// Builds ESC/POS bytes for a sale and pushes them to a Bluetooth printer.
class ReceiptPrinter {
  ReceiptPrinter({
    required this.storeSettings,
    this.paperSize = PaperSize.mm58,
  });

  final StoreSettings storeSettings;
  final PaperSize paperSize;

  Stream<List<Printer>> get devices => FlutterThermalPrinter.instance.devicesStream;

  Future<void> startScan({ConnectionType? type}) {
    if (kIsWeb) return Future.value();
    return FlutterThermalPrinter.instance.getPrinters(
      connectionTypes: type != null
          ? <ConnectionType>[type]
          : const <ConnectionType>[ConnectionType.USB, ConnectionType.BLE],
      refreshDuration: const Duration(seconds: 1),
    );
  }

  Future<void> stopScan() {
    if (kIsWeb) return Future.value();
    return FlutterThermalPrinter.instance.stopScan();
  }

  /// Mencetak struk langsung ke printer thermal (kabel USB / driver Windows) melalui browser atau dialog sistem.
  void printViaBrowser(
    Sale sale, {
    double? paidAmount,
    double? changeAmount,
  }) {
    final html = buildReceiptHtml(
      sale,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
    );
    printReceiptViaBrowser(htmlContent: html);
  }

  Future<void> printSale(
    Printer printer,
    Sale sale, {
    double? paidAmount,
    double? changeAmount,
  }) async {
    final bytes = await buildReceipt(
      sale,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
    );
    final connected = await FlutterThermalPrinter.instance.connect(printer);

    if (!connected) {
      throw StateError('Gagal terhubung ke ${printer.name ?? 'printer'}.');
    }

    try {
      await FlutterThermalPrinter.instance.printData(printer, bytes);
    } finally {
      await FlutterThermalPrinter.instance.disconnect(printer);
    }
  }

  static CapabilityProfile? _cachedProfile;

  /// 58 mm paper fits 32 characters per line; 80 mm fits 48 characters.
  Future<List<int>> buildReceipt(
    Sale sale, {
    double? paidAmount,
    double? changeAmount,
  }) async {
    final profile = _cachedProfile ??= await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final bytes = <int>[];

    bytes.addAll(generator.reset());

    // Header Toko
    bytes.addAll(
      generator.text(
        storeSettings.name,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    if (storeSettings.address.isNotEmpty) {
      bytes.addAll(
        generator.text(
          storeSettings.address,
          styles: const PosStyles(align: PosAlign.center),
        ),
      );
    }
    if (storeSettings.phone.isNotEmpty) {
      bytes.addAll(
        generator.text(
          'Telp: ${storeSettings.phone}',
          styles: const PosStyles(align: PosAlign.center),
        ),
      );
    }

    bytes.addAll(generator.hr());

    // Informasi Transaksi
    bytes.addAll(
      generator.row(<PosColumn>[
        PosColumn(
          text: 'No: #${sale.id}',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: formatDateTime(sale.createdAt),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );

    bytes.addAll(
      generator.row(<PosColumn>[
        PosColumn(text: 'Kasir: ${sale.cashierName ?? 'Staff'}', width: 6),
        PosColumn(
          text: 'Pelanggan: ${sale.buyerName ?? 'Umum'}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );

    bytes.addAll(generator.hr());

    // Daftar Item
    for (final item in sale.items) {
      bytes.addAll(
        generator.text(
          item.productName,
          styles: const PosStyles(bold: true),
        ),
      );
      bytes.addAll(
        generator.row(<PosColumn>[
          PosColumn(
            text: '${item.quantity} x ${formatRupiah(item.sellingPrice)}',
            width: 7,
          ),
          PosColumn(
            text: formatRupiah(item.subtotal),
            width: 5,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    bytes.addAll(generator.hr());

    // Total Belanja
    bytes.addAll(
      generator.row(<PosColumn>[
        PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: formatRupiah(sale.totalAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]),
    );

    // Tunai & Kembalian jika ada
    if (paidAmount != null && paidAmount > 0) {
      bytes.addAll(
        generator.row(<PosColumn>[
          PosColumn(text: 'Tunai', width: 6),
          PosColumn(
            text: formatRupiah(paidAmount),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
      final change = changeAmount ?? (paidAmount - sale.totalAmount);
      bytes.addAll(
        generator.row(<PosColumn>[
          PosColumn(text: 'Kembalian', width: 6),
          PosColumn(
            text: formatRupiah(change < 0 ? 0 : change),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    bytes.addAll(generator.hr());

    // Footer Catatan Toko
    final footerLines = storeSettings.footerNote.split('\n');
    for (final line in footerLines) {
      if (line.trim().isNotEmpty) {
        bytes.addAll(
          generator.text(
            line.trim(),
            styles: const PosStyles(align: PosAlign.center),
          ),
        );
      }
    }

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }

  /// Menghasilkan format teks nota rapi untuk dibagikan via WhatsApp atau disalin.
  String formatReceiptText(
    Sale sale, {
    double? paidAmount,
    double? changeAmount,
  }) {
    final buffer = StringBuffer();
    const divider = '================================';
    const subDivider = '--------------------------------';

    buffer.writeln(storeSettings.name.toUpperCase());
    if (storeSettings.address.isNotEmpty) {
      buffer.writeln(storeSettings.address);
    }
    if (storeSettings.phone.isNotEmpty) {
      buffer.writeln('Telp: ${storeSettings.phone}');
    }
    buffer.writeln(divider);
    buffer.writeln('No. Struk : #${sale.id}');
    buffer.writeln('Tanggal   : ${formatDateTime(sale.createdAt)}');
    buffer.writeln('Kasir     : ${sale.cashierName ?? 'Staff'}');
    buffer.writeln('Pelanggan : ${sale.buyerName ?? 'Umum'}');
    buffer.writeln(subDivider);

    for (final item in sale.items) {
      buffer.writeln(item.productName);
      final qtyPrice = '  ${item.quantity} x ${formatRupiah(item.sellingPrice)}';
      final subtotal = formatRupiah(item.subtotal);
      final spaces = 32 - qtyPrice.length - subtotal.length;
      buffer.writeln('$qtyPrice${spaces > 0 ? ' ' * spaces : '  '}$subtotal');
    }

    buffer.writeln(subDivider);
    final totalLabel = 'TOTAL';
    final totalValue = formatRupiah(sale.totalAmount);
    final totalSpaces = 32 - totalLabel.length - totalValue.length;
    buffer.writeln('$totalLabel${totalSpaces > 0 ? ' ' * totalSpaces : '  '}$totalValue');

    if (paidAmount != null && paidAmount > 0) {
      final cashLabel = 'Tunai';
      final cashVal = formatRupiah(paidAmount);
      final cashSpaces = 32 - cashLabel.length - cashVal.length;
      buffer.writeln('$cashLabel${cashSpaces > 0 ? ' ' * cashSpaces : '  '}$cashVal');

      final change = changeAmount ?? (paidAmount - sale.totalAmount);
      final changeLabel = 'Kembalian';
      final changeVal = formatRupiah(change < 0 ? 0 : change);
      final changeSpaces = 32 - changeLabel.length - changeVal.length;
      buffer.writeln('$changeLabel${changeSpaces > 0 ? ' ' * changeSpaces : '  '}$changeVal');
    }

    buffer.writeln(divider);
    final footerLines = storeSettings.footerNote.split('\n');
    for (final line in footerLines) {
      if (line.trim().isNotEmpty) {
        buffer.writeln(line.trim());
      }
    }

    return buffer.toString();
  }

  /// Menghasilkan format HTML struk yang disesuaikan untuk kertas thermal 58mm atau 80mm
  /// untuk dicetak langsung menggunakan printer kabel USB / driver Windows di browser.
  String buildReceiptHtml(
    Sale sale, {
    double? paidAmount,
    double? changeAmount,
  }) {
    final widthMm = storeSettings.paperSizeMm;
    final fontSize = widthMm == 80 ? 12 : 11;
    final titleSize = widthMm == 80 ? 16 : 14;
    final finalPaid = paidAmount ?? sale.totalAmount;
    final finalChange = changeAmount ?? (finalPaid - sale.totalAmount);

    final itemRows = sale.items.map((item) {
      return '''
        <div class="item-block">
          <div class="item-name">${_escapeHtml(item.productName)}</div>
          <div class="row">
            <span>${item.quantity} x ${formatRupiah(item.sellingPrice)}</span>
            <span class="bold">${formatRupiah(item.subtotal)}</span>
          </div>
        </div>
      ''';
    }).join('');

    final footerLines = storeSettings.footerNote
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map((l) => '<div class="footer-line">${_escapeHtml(l.trim())}</div>')
        .join('');

    final paymentSection = (paidAmount != null && paidAmount > 0)
        ? '''
        <div class="row">
          <span>Tunai</span>
          <span>${formatRupiah(finalPaid)}</span>
        </div>
        <div class="row bold">
          <span>Kembalian</span>
          <span>${formatRupiah(finalChange < 0 ? 0 : finalChange)}</span>
        </div>
      '''
        : '';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Struk BN Mart #${sale.id}</title>
  <style>
    @page {
      size: ${widthMm}mm auto;
      margin: 0;
    }
    @media print {
      html, body {
        width: ${widthMm}mm;
        margin: 0 !important;
        padding: 0 !important;
        background: #fff;
      }
    }
    body {
      width: ${widthMm}mm;
      margin: 0 auto;
      padding: 6px 8px 12px 8px;
      font-family: 'Courier New', Courier, monospace;
      font-size: ${fontSize}px;
      line-height: 1.35;
      color: #000;
      box-sizing: border-box;
      background: #fff;
    }
    .center { text-align: center; }
    .bold { font-weight: bold; }
    .store-name {
      font-size: ${titleSize}px;
      font-weight: 800;
      letter-spacing: 0.5px;
      margin-bottom: 2px;
    }
    .divider {
      border-top: 1px dashed #000;
      margin: 6px 0;
    }
    .double-divider {
      border-top: 2px dashed #000;
      margin: 6px 0;
    }
    .row {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
    }
    .item-block {
      margin-bottom: 4px;
    }
    .item-name {
      font-weight: bold;
      word-break: break-word;
    }
    .total-row {
      font-size: ${fontSize + 2}px;
      font-weight: 800;
      margin: 2px 0;
    }
    .footer-line {
      text-align: center;
      font-size: ${fontSize - 1}px;
    }
    .cut-spacing {
      height: 15mm;
    }
  </style>
</head>
<body>
  <div class="center store-name">${_escapeHtml(storeSettings.name.toUpperCase())}</div>
  ${storeSettings.address.isNotEmpty ? '<div class="center">${_escapeHtml(storeSettings.address)}</div>' : ''}
  ${storeSettings.phone.isNotEmpty ? '<div class="center">Telp: ${_escapeHtml(storeSettings.phone)}</div>' : ''}
  <div class="divider"></div>
  <div class="row">
    <span>No: #${sale.id}</span>
    <span>${formatDateTime(sale.createdAt)}</span>
  </div>
  <div class="row">
    <span>Kasir: ${_escapeHtml(sale.cashierName ?? 'Staff')}</span>
    <span>Plg: ${_escapeHtml(sale.buyerName ?? 'Umum')}</span>
  </div>
  <div class="divider"></div>
  $itemRows
  <div class="divider"></div>
  <div class="row total-row">
    <span>TOTAL</span>
    <span>${formatRupiah(sale.totalAmount)}</span>
  </div>
  $paymentSection
  <div class="double-divider"></div>
  $footerLines
  <div class="cut-spacing"></div>
</body>
</html>
''';
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }
}
