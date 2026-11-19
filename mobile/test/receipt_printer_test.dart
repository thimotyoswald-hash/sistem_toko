import 'package:flutter_test/flutter_test.dart';
import 'package:pos_mobile/features/pos/data/receipt_printer.dart';
import 'package:pos_mobile/features/pos/data/store_settings.dart';
import 'package:pos_mobile/features/pos/domain/sale.dart';

void main() {
  group('ReceiptPrinter Tests', () {
    final storeSettings58 = StoreSettings(
      name: 'Bagimu Negriku Market (BN Mart)',
      address: 'Jl. Merdeka No. 45',
      phone: '08123456789',
      footerNote: 'Terima kasih atas kunjungan Anda\nBarang yang dibeli tidak dapat ditukar',
      paperSizeMm: 58,
    );

    final storeSettings80 = StoreSettings(
      name: 'Bagimu Negriku Market (BN Mart)',
      address: 'Jl. Merdeka No. 45',
      phone: '08123456789',
      footerNote: 'Terima kasih atas kunjungan Anda',
      paperSizeMm: 80,
    );

    final testSale = Sale(
      id: 101,
      totalAmount: 50000,
      createdAt: DateTime(2026, 11, 18, 14, 0),
      buyerName: 'Budi Santoso',
      cashierName: 'Siti',
      items: const [
        SaleItem(
          productId: 1,
          productName: 'Beras Pandan Wangi 5kg',
          quantity: 1,
          sellingPrice: 50000,
          subtotal: 50000,
        ),
      ],
    );

    test('buildReceiptHtml formats correctly for 58mm wired thermal print', () {
      final printer = ReceiptPrinter(storeSettings: storeSettings58);
      final html = printer.buildReceiptHtml(
        testSale,
        paidAmount: 100000,
        changeAmount: 50000,
      );

      expect(html, contains('BAGIMU NEGRIKU MARKET (BN MART)'));
      expect(html, contains('size: 58mm auto'));
      expect(html, contains('width: 58mm'));
      expect(html, contains('No: #101'));
      expect(html, contains('Beras Pandan Wangi 5kg'));
      expect(html, contains('TOTAL'));
      expect(html, contains('Tunai'));
      expect(html, contains('Kembalian'));
      expect(html, contains('Terima kasih atas kunjungan Anda'));
    });

    test('buildReceiptHtml adjusts size to 80mm when configured', () {
      final printer = ReceiptPrinter(storeSettings: storeSettings80);
      final html = printer.buildReceiptHtml(testSale);

      expect(html, contains('size: 80mm auto'));
      expect(html, contains('width: 80mm'));
    });

    test('formatReceiptText contains transaction details', () {
      final printer = ReceiptPrinter(storeSettings: storeSettings58);
      final text = printer.formatReceiptText(
        testSale,
        paidAmount: 60000,
        changeAmount: 10000,
      );

      expect(text, contains('BAGIMU NEGRIKU MARKET'));
      expect(text, contains('#101'));
      expect(text, contains('Beras Pandan Wangi 5kg'));
      expect(text, contains('TOTAL'));
      expect(text, contains('Tunai'));
      expect(text, contains('Kembalian'));
    });
  });
}
