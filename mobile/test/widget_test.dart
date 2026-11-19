import 'package:flutter_test/flutter_test.dart';

import 'package:pos_mobile/core/utils/formatters.dart';

void main() {
  test('formatRupiah formats thousands', () {
    expect(formatRupiah(15000), 'Rp 15.000');
    expect(formatRupiah(0), 'Rp 0');
  });
}
