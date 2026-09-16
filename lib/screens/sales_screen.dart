import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../services/calculations.dart';
import '../services/shop_repository.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final repo = ShopRepository();
  final search = TextEditingController();
  late Future<List<Map<String, dynamic>>> future;
  String query = '';

  @override
  void initState() {
    super.initState();
    future = repo.loadTransactions();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() => future = repo.loadTransactions());
    await future;
  }

  bool matches(Map<String, dynamic> row, String q) {
    if (q.isEmpty) return true;

    final values = [
      row['id'],
      row['customer_name'],
      row['car_make'],
      row['car_model'],
      row['part_name'],
      row['part_brand'],
      row['notes'],
    ];

    final text = values
        .where((e) => e != null)
        .map((e) => e.toString().toLowerCase())
        .join(' ');

    return text.contains(q.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: FilledButton.icon(
              onPressed: refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          );
        }

        final all = snapshot.data ?? [];
        final returned = returnedAmountMap(all);

        final visible = all.where((row) => matches(row, query)).toList();

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            children: [
              TextField(
                controller: search,
                onChanged: (value) => setState(() => query = value.trim()),
                decoration: InputDecoration(
                  hintText: 'بحث باسم الزبون، رقم العملية، القطعة أو السيارة',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            search.clear();
                            setState(() => query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${visible.length} عملية',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (visible.isEmpty)
                const _EmptySales()
              else
                ...visible.map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TransactionCard(
                      row: row,
                      remaining: row['transaction_type'] == 'sale'
                          ? remainingForSale(row, returned)
                          : 0,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final double remaining;

  const _TransactionCard({
    required this.row,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final isReturn = row['transaction_type'] == 'return';
    final date = DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();
    final dateText = date == null
        ? '—'
        : DateFormat('dd/MM  HH:mm').format(date);

    final total = asDouble(row['total_price']);
    final paid = asDouble(row['amount_paid']);
    final currency = safeText(row['currency'], fallback: 'SYP');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          builder: (_) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: _TransactionDetails(
              row: row,
              remaining: remaining,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isReturn ? AppColors.softPink : AppColors.softBlue,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      isReturn
                          ? Icons.keyboard_return_rounded
                          : Icons.shopping_bag_outlined,
                      color: isReturn ? AppColors.pink : AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          safeText(row['customer_name'], fallback: 'بدون اسم'),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '#${safeText(row['id'])} • $dateText',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isReturn ? AppColors.softPink : AppColors.softGreen,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isReturn ? 'مرتجع' : 'بيع',
                      style: TextStyle(
                        color: isReturn ? AppColors.pink : AppColors.green,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              _InfoLine(
                icon: Icons.settings_outlined,
                label: 'القطعة',
                value: safeText(row['part_name']),
              ),
              _InfoLine(
                icon: Icons.directions_car_outlined,
                label: 'السيارة',
                value: '${safeText(row['car_make'])} ${safeText(row['car_model'], fallback: '')}'.trim(),
              ),
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _MoneyMini(
                      label: 'الإجمالي',
                      value: '${compactNumber(total)} $currency',
                      color: AppColors.text,
                    ),
                  ),
                  if (!isReturn) ...[
                    Expanded(
                      child: _MoneyMini(
                        label: 'المدفوع',
                        value: '${compactNumber(paid)} $currency',
                        color: AppColors.green,
                      ),
                    ),
                    Expanded(
                      child: _MoneyMini(
                        label: 'المتبقي',
                        value: '${compactNumber(remaining)} $currency',
                        color: remaining > 0
                            ? AppColors.orange
                            : AppColors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.muted),
          const SizedBox(width: 7),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyMini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MoneyMini({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionDetails extends StatelessWidget {
  final Map<String, dynamic> row;
  final double remaining;

  const _TransactionDetails({
    required this.row,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final isReturn = row['transaction_type'] == 'return';

    final details = <MapEntry<String, String>>[
      MapEntry('رقم العملية', '#${safeText(row['id'])}'),
      MapEntry('النوع', isReturn ? 'مرتجع' : 'بيع'),
      MapEntry('الزبون', safeText(row['customer_name'])),
      MapEntry('السيارة', '${safeText(row['car_make'])} ${safeText(row['car_model'], fallback: '')}'.trim()),
      MapEntry('القطعة', safeText(row['part_name'])),
      MapEntry('الماركة', safeText(row['part_brand'])),
      MapEntry('الكمية', safeText(row['quantity'])),
      MapEntry('السعر الإجمالي', compactNumber(asDouble(row['total_price']))),
      if (!isReturn) MapEntry('المدفوع', compactNumber(asDouble(row['amount_paid']))),
      if (!isReturn) MapEntry('المتبقي', compactNumber(remaining)),
      MapEntry('العملة', safeText(row['currency'], fallback: 'SYP')),
      if (isReturn)
        MapEntry('البيعة الأصلية', safeText(row['related_sale_id'])),
      MapEntry('الملاحظات', safeText(row['notes'])),
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          14,
          18,
          MediaQuery.of(context).viewInsets.bottom + 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'تفاصيل العملية',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: details.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final item = details[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            item.key,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.value,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySales extends StatelessWidget {
  const _EmptySales();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 50),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 52, color: AppColors.muted),
          SizedBox(height: 12),
          Text(
            'ما في عمليات مطابقة',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
