import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/calculations.dart';
import '../services/shop_repository.dart';
import '../widgets/stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final repo = ShopRepository();
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = repo.loadTransactions();
  }

  Future<void> refresh() async {
    setState(() => future = repo.loadTransactions());
    await future;
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

        final rows = snapshot.data ?? [];
        final returnedMap = returnedAmountMap(rows);
        final now = DateTime.now();

        bool thisMonth(Map<String, dynamic> row) {
          final d = DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();
          return d != null && d.year == now.year && d.month == now.month;
        }

        final monthRows = rows.where(thisMonth).toList();
        final monthSales = monthRows
            .where((e) => e['transaction_type'] == 'sale')
            .toList();
        final monthReturns = monthRows
            .where((e) => e['transaction_type'] == 'return')
            .toList();

        final salesTotal = monthSales.fold<double>(
          0,
          (sum, row) => sum + asDouble(row['total_price']),
        );
        final returnsTotal = monthReturns.fold<double>(
          0,
          (sum, row) => sum + asDouble(row['total_price']),
        );

        final debt = rows
            .where((e) => e['transaction_type'] == 'sale')
            .fold<double>(
              0,
              (sum, row) => sum + remainingForSale(row, returnedMap),
            );

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            children: [
              StatCard(
                title: 'مبيعات هذا الشهر',
                value: compactNumber(salesTotal),
                icon: Icons.trending_up_rounded,
                accent: AppColors.blue,
                soft: AppColors.softBlue,
              ),
              const SizedBox(height: 10),
              StatCard(
                title: 'مرتجعات هذا الشهر',
                value: compactNumber(returnsTotal),
                icon: Icons.keyboard_return_rounded,
                accent: AppColors.pink,
                soft: AppColors.softPink,
              ),
              const SizedBox(height: 10),
              StatCard(
                title: 'صافي الشهر',
                value: compactNumber(salesTotal - returnsTotal),
                icon: Icons.account_balance_rounded,
                accent: AppColors.green,
                soft: AppColors.softGreen,
              ),
              const SizedBox(height: 10),
              StatCard(
                title: 'إجمالي المتبقي على الزبائن',
                value: compactNumber(debt),
                icon: Icons.payments_outlined,
                accent: AppColors.orange,
                soft: AppColors.softOrange,
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.picture_as_pdf_outlined, color: AppColors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'تصدير PDF ومشاركة التقارير ممكن نضيفهم بالنسخة التالية بعد تثبيت النسخة الأساسية والتأكد من الحسابات.',
                          style: TextStyle(
                            color: AppColors.muted,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
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
