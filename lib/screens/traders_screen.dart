import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../services/calculations.dart';
import '../services/shop_repository.dart';

class TradersScreen extends StatefulWidget {
  const TradersScreen({super.key});

  @override
  State<TradersScreen> createState() => _TradersScreenState();
}

class _TradersScreenState extends State<TradersScreen> {
  final repo = ShopRepository();
  late Future<_TraderData> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<_TraderData> load() async {
    final results = await Future.wait([
      repo.loadMerchants(),
      repo.loadLedger(),
    ]);

    return _TraderData(
      merchants: results[0],
      ledger: results[1],
    );
  }

  Future<void> refresh() async {
    setState(() => future = load());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TraderData>(
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

        final data = snapshot.data!;
        final byMerchant = <int, double>{};
        double total = 0;

        for (final row in data.ledger) {
          final id = asInt(row['merchant_id']);
          if (id == null) continue;
          final signed =
              asDouble(row['amount']) * asDouble(row['balance_effect']);
          byMerchant[id] = (byMerchant[id] ?? 0) + signed;
          total += signed;
        }

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Text(
                        'الصافي الكلي مع كل التجار',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${total >= 0 ? '+' : ''}${compactNumber(total)}',
                        style: TextStyle(
                          color: total >= 0 ? AppColors.green : AppColors.pink,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        total >= 0 ? 'إلك عند التجار' : 'إلهم عندك',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: data.merchants.isEmpty
                          ? null
                          : () async {
                              final changed = await showModalBottomSheet<bool>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                builder: (_) => Directionality(
                                  textDirection: ui.TextDirection.rtl,
                                  child: AddTraderMovementSheet(
                                    merchants: data.merchants,
                                  ),
                                ),
                              );

                              if (changed == true) {
                                await refresh();
                              }
                            },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('إضافة حركة'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final changed = await showDialog<bool>(
                        context: context,
                        builder: (_) => Directionality(
                          textDirection: ui.TextDirection.rtl,
                          child: const AddMerchantDialog(),
                        ),
                      );

                      if (changed == true) {
                        await refresh();
                      }
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('تاجر'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'التجار',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              if (data.merchants.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Text(
                      'ما في تجار مضافين بعد.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              else
                ...data.merchants.map((merchant) {
                  final id = asInt(merchant['id'])!;
                  final net = byMerchant[id] ?? 0;
                  final entries = data.ledger
                      .where((e) => asInt(e['merchant_id']) == id)
                      .toList();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: net >= 0
                              ? AppColors.softGreen
                              : AppColors.softPink,
                          child: Icon(
                            Icons.store_mall_directory_outlined,
                            color: net >= 0
                                ? AppColors.green
                                : AppColors.pink,
                          ),
                        ),
                        title: Text(
                          safeText(merchant['name']),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          '${entries.length} حركة',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        trailing: Text(
                          '${net >= 0 ? '+' : ''}${compactNumber(net)}',
                          style: TextStyle(
                            color: net >= 0
                                ? AppColors.green
                                : AppColors.pink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        onTap: () async {
                          final changed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => Directionality(
                                textDirection: ui.TextDirection.rtl,
                                child: TraderDetailsScreen(
                                  merchant: merchant,
                                  ledger: entries,
                                  net: net,
                                ),
                              ),
                            ),
                          );

                          if (changed == true) {
                            await refresh();
                          }
                        },
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _TraderData {
  final List<Map<String, dynamic>> merchants;
  final List<Map<String, dynamic>> ledger;

  const _TraderData({
    required this.merchants,
    required this.ledger,
  });
}

class AddMerchantDialog extends StatefulWidget {
  const AddMerchantDialog({super.key});

  @override
  State<AddMerchantDialog> createState() => _AddMerchantDialogState();
}

class _AddMerchantDialogState extends State<AddMerchantDialog> {
  final controller = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final name = controller.text.trim();
    if (name.isEmpty) return;

    setState(() => loading = true);

    try {
      await ShopRepository().addMerchant(name);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إضافة التاجر: $e')),
      );
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة تاجر'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'اسم التاجر',
          hintText: 'مثال: أحمد علي',
        ),
        onSubmitted: (_) => save(),
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: loading ? null : save,
          child: Text(loading ? 'جاري الحفظ...' : 'حفظ'),
        ),
      ],
    );
  }
}

class AddTraderMovementSheet extends StatefulWidget {
  final List<Map<String, dynamic>> merchants;
  final Map<String, dynamic>? existing;

  const AddTraderMovementSheet({
    super.key,
    required this.merchants,
    this.existing,
  });

  @override
  State<AddTraderMovementSheet> createState() => _AddTraderMovementSheetState();
}

class _AddTraderMovementSheetState extends State<AddTraderMovementSheet> {
  final amount = TextEditingController();
  final notes = TextEditingController();

  int? merchantId;
  String movement = 'invoice_from_him';
  String currency = 'SYP';
  DateTime date = DateTime.now();
  bool loading = false;

  static const movementData = {
    'invoice_from_him': ('فاتورة', -1),
    'i_paid_for_him': ('دفعت عن', 1),
    'he_paid_for_me': ('سدد عني', -1),
  };

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    if (existing != null) {
      merchantId = asInt(existing['merchant_id']);
      movement = existing['movement_type']?.toString() ?? movement;
      currency = existing['currency']?.toString() ?? currency;
      amount.text = asDouble(existing['amount']).toStringAsFixed(0);
      notes.text = existing['notes']?.toString() ?? '';
      date = DateTime.tryParse(existing['movement_date']?.toString() ?? '') ??
          DateTime.now();
    } else if (widget.merchants.isNotEmpty) {
      merchantId = asInt(widget.merchants.first['id']);
    }
  }

  @override
  void dispose() {
    amount.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = double.tryParse(amount.text.replaceAll(',', '').trim());

    if (merchantId == null || value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل مبلغ صحيح')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final info = movementData[movement]!;

      if (widget.existing == null) {
        await ShopRepository().addLedgerMovement(
          merchantId: merchantId!,
          movementType: movement,
          balanceEffect: info.$2,
          amount: value,
          currency: currency,
          movementDate: date,
          notes: notes.text,
        );
      } else {
        await ShopRepository().updateLedgerMovement(
          id: asInt(widget.existing!['id'])!,
          movementType: movement,
          balanceEffect: info.$2,
          amount: value,
          currency: currency,
          movementDate: date,
          notes: notes.text,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحفظ: $e')),
      );
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
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
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  widget.existing == null ? 'إضافة حركة تاجر' : 'تعديل الحركة',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: merchantId,
                decoration: const InputDecoration(labelText: 'التاجر'),
                items: widget.merchants
                    .map(
                      (m) => DropdownMenuItem<int>(
                        value: asInt(m['id']),
                        child: Text(safeText(m['name'])),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => merchantId = value),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: movement,
                decoration: const InputDecoration(labelText: 'نوع الحركة'),
                items: movementData.entries
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value.$1),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => movement = value);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'المبلغ'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: currency,
                      decoration: const InputDecoration(labelText: 'العملة'),
                      items: const [
                        DropdownMenuItem(value: 'SYP', child: Text('SYP')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => currency = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) setState(() => date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'التاريخ',
                    suffixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(date)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  hintText: 'اختياري',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: loading ? null : save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(loading ? 'جاري الحفظ...' : 'حفظ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TraderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> merchant;
  final List<Map<String, dynamic>> ledger;
  final double net;

  const TraderDetailsScreen({
    super.key,
    required this.merchant,
    required this.ledger,
    required this.net,
  });

  @override
  State<TraderDetailsScreen> createState() => _TraderDetailsScreenState();
}

class _TraderDetailsScreenState extends State<TraderDetailsScreen> {
  bool changed = false;

  String movementLabel(String? key) {
    switch (key) {
      case 'invoice_from_him':
        return 'فاتورة';
      case 'i_paid_for_him':
        return 'دفعت عن';
      case 'he_paid_for_me':
        return 'سدد عني';
      default:
        return key ?? '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            safeText(widget.merchant['name']),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context, changed),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Text(
                      'صافي الحساب',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${widget.net >= 0 ? '+' : ''}${compactNumber(widget.net)}',
                      style: TextStyle(
                        color: widget.net >= 0
                            ? AppColors.green
                            : AppColors.pink,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'الحركات',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.ledger.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: Text(
                    'لا يوجد حركات.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              )
            else
              ...widget.ledger.map((row) {
                final effect = asDouble(row['balance_effect']);
                final signed = asDouble(row['amount']) * effect;
                final positive = signed >= 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: positive
                            ? AppColors.softGreen
                            : AppColors.softPink,
                        child: Icon(
                          positive
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          color: positive
                              ? AppColors.green
                              : AppColors.pink,
                        ),
                      ),
                      title: Text(
                        movementLabel(row['movement_type']?.toString()),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(
                        '${safeText(row['movement_date'])}'
                        '${safeText(row['notes'], fallback: '').isEmpty ? '' : ' • ${safeText(row['notes'])}'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        '${signed >= 0 ? '+' : ''}${compactNumber(signed)} ${safeText(row['currency'], fallback: 'SYP')}',
                        style: TextStyle(
                          color: positive
                              ? AppColors.green
                              : AppColors.pink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      onLongPress: () async {
                        final action = await showModalBottomSheet<String>(
                          context: context,
                          backgroundColor: Colors.white,
                          builder: (sheetContext) => Directionality(
                            textDirection: ui.TextDirection.rtl,
                            child: SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit_outlined),
                                    title: const Text('تعديل'),
                                    onTap: () => Navigator.pop(sheetContext, 'edit'),
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.pink,
                                    ),
                                    title: const Text(
                                      'حذف',
                                      style: TextStyle(color: AppColors.pink),
                                    ),
                                    onTap: () => Navigator.pop(sheetContext, 'delete'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        if (!mounted || action == null) return;

                        if (action == 'delete') {
                          final yes = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('حذف الحركة؟'),
                              content: const Text(
                                'سيتم حذف الحركة من حساب التاجر.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: const Text('إلغاء'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                  child: const Text('حذف'),
                                ),
                              ],
                            ),
                          );

                          if (yes == true) {
                            await ShopRepository().deleteLedgerMovement(
                              asInt(row['id'])!,
                            );
                            if (!mounted) return;
                            setState(() {
                              widget.ledger.remove(row);
                              changed = true;
                            });
                          }
                        } else if (action == 'edit') {
                          final saved = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            builder: (_) => Directionality(
                              textDirection: ui.TextDirection.rtl,
                              child: AddTraderMovementSheet(
                                merchants: [widget.merchant],
                                existing: row,
                              ),
                            ),
                          );

                          if (saved == true && mounted) {
                            Navigator.pop(context, true);
                          }
                        }
                      },
                    ),
                  ),
                );
              }),
            const SizedBox(height: 14),
            const Text(
              'اضغط ضغطة مطوّلة على أي حركة للتعديل أو الحذف.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
