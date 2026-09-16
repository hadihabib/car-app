double asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int? asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

Map<int, double> returnedAmountMap(
  List<Map<String, dynamic>> transactions,
) {
  final map = <int, double>{};

  for (final row in transactions) {
    if (row['transaction_type'] != 'return') continue;

    final saleId = asInt(row['related_sale_id']);
    if (saleId == null) continue;

    map[saleId] = (map[saleId] ?? 0) + asDouble(row['total_price']);
  }

  return map;
}

double remainingForSale(
  Map<String, dynamic> sale,
  Map<int, double> returned,
) {
  final id = asInt(sale['id']);
  final total = asDouble(sale['total_price']);
  final paid = asDouble(sale['amount_paid']);
  final returnedTotal = id == null ? 0 : (returned[id] ?? 0);
  final effectiveTotal = (total - returnedTotal).clamp(0, double.infinity);
  return (effectiveTotal - paid).clamp(0, double.infinity);
}

String compactNumber(num value) {
  final rounded = value.round();
  final raw = rounded.abs().toString();
  final parts = <String>[];

  for (var i = raw.length; i > 0; i -= 3) {
    final start = (i - 3).clamp(0, i);
    parts.insert(0, raw.substring(start, i));
  }

  return '${rounded < 0 ? '-' : ''}${parts.join(',')}';
}

String safeText(dynamic value, {String fallback = '—'}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}
