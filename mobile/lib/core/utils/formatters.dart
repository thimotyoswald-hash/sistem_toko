const List<String> _shortMonths = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

const List<String> monthNames = <String>[
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// `15000` becomes `Rp 15.000`, matching how the receipt printer expects prices.
String formatRupiah(num value) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[index]);
  }

  return '${rounded < 0 ? '-' : ''}Rp $buffer';
}

/// `2026-11-05T09:21:50+00:00` becomes `05 Nov 2026 16:21` in local time.
String formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day ${_shortMonths[local.month - 1]} ${local.year} $hour:$minute';
}

String formatDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  return '$day ${_shortMonths[local.month - 1]} ${local.year}';
}

String formatDayLabel(String isoDate) {
  final parsed = DateTime.tryParse(isoDate);
  return parsed == null ? isoDate : '${parsed.day} ${_shortMonths[parsed.month - 1]}';
}

/// Parses `2026-11-05T09:21:50+00:00` without throwing on null/garbage.
DateTime parseApiDate(Object? raw) {
  if (raw is String) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return parsed;
    }
  }
  return DateTime.now();
}
