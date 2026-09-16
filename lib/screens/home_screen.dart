import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/calculations.dart';
import '../services/shop_repository.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ErrorView(onRetry: refresh);
        }

        final rows = snapshot.data ?? [];
        final returned = returnedAmountMap(rows);
        final now = DateTime.now();

        final sales = rows.where((e) => e['transaction_type'] == 'sale').toList();
        final returns = rows.where((e) => e['transaction_type'] == 'return').toList();

        final todaySales = sales.where((row) {
          final d = DateTime.tryParse(row['created_at']?.toString() ?? '');
          return d != null && sameDay(d.toLocal(), now);
        }).toList();

        final todayReturns = returns.where((row) {
          final d = DateTime.tryParse(row['created_at']?.toString() ?? '');
          return d != null && sameDay(d.toLocal(), now);
        }).toList();

        final todaySalesTotal = todaySales.fold<double>(
          0,
          (sum, row) => sum + asDouble(row['total_price']),
        );

        final todayReturnsTotal = todayReturns.fold<double>(
          0,
          (sum, row) => sum + asDouble(row['total_price']),
        );

        final totalDebt = sales.fold<double>(
          0,
          (sum, row) => sum + remainingForSale(row, returned),
        );

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const Text(
                'ملخص سريع',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'اسحب للأسفل لتحديث البيانات',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              StatCard(
                title: 'مبيعات اليوم',
                value: compactNumber(todaySalesTotal),
                icon: Icons.trending_up_rounded,
                accent: AppColors.blue,
                soft: AppColors.softBlue,
              ),
              const SizedBox(height: 10),
              StatCard(
                title: 'مرتجعات اليوم',
                value: compactNumber(todayReturnsTotal),
                icon: Icons.keyboard_return_rounded,
                accent: AppColors.pink,
                soft: AppColors.softPink,
              ),
              const SizedBox(height: 10),
              StatCard(
                title: 'ديون الزبائن الحالية',
                value: compactNumber(totalDebt),
                icon: Icons.account_balance_wallet_outlined,
                accent: AppColors.orange,
                soft: AppColors.softOrange,
              ),
              const SizedBox(height: 10),
              StatCard(
                title: 'عمليات اليوم',
                value: '${todaySales.length + todayReturns.length}',
                icon: Icons.receipt_long_rounded,
                accent: AppColors.green,
                soft: AppColors.softGreen,
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'إدخال المبيعات والمرتجعات ودفعات الزبائن يبقى من بوت Telegram. التطبيق للمتابعة وإدارة حسابات التجار.',
                          style: TextStyle(
                            color: AppColors.text.withValues(alpha: .82),
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

class _ErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.pink),
            const SizedBox(height: 12),
            const Text(
              'تعذر تحميل البيانات',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
