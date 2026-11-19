import 'receipt_web_printer_stub.dart'
    if (dart.library.js_interop) 'receipt_web_printer_web.dart';

void printReceiptViaBrowser({required String htmlContent}) {
  printReceiptHtml(htmlContent: htmlContent);
}
