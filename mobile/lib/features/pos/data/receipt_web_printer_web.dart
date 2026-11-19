import 'dart:js_interop';
import 'package:web/web.dart' as web;

void printReceiptHtml({required String htmlContent}) {
  final existing = web.document.getElementById('pos_receipt_print_frame');
  if (existing != null) {
    existing.remove();
  }

  final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
  iframe.id = 'pos_receipt_print_frame';
  iframe.style.position = 'fixed';
  iframe.style.right = '0';
  iframe.style.bottom = '0';
  iframe.style.width = '0';
  iframe.style.height = '0';
  iframe.style.border = '0';
  iframe.srcdoc = htmlContent.toJS;

  iframe.onLoad.listen((_) {
    final win = iframe.contentWindow;
    if (win != null) {
      win.focus();
      win.print();
    }
  });

  web.document.body?.appendChild(iframe);
}
