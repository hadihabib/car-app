import 'package:supabase_flutter/supabase_flutter.dart';

class ShopRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> loadTransactions({
    int limit = 1000,
  }) async {
    final rows = await _db
        .from('transactions')
        .select()
        .neq('status', 'cancelled')
        .order('id', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> loadMerchants() async {
    final rows = await _db
        .from('merchants')
        .select()
        .eq('is_active', true)
        .order('name');

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> loadLedger() async {
    final rows = await _db
        .from('merchant_ledger')
        .select()
        .order('id', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addMerchant(String name) async {
    await _db.from('merchants').insert({
      'name': name.trim(),
      'is_active': true,
    });
  }

  Future<void> addLedgerMovement({
    required int merchantId,
    required String movementType,
    required int balanceEffect,
    required double amount,
    required String currency,
    required DateTime movementDate,
    String? notes,
  }) async {
    await _db.from('merchant_ledger').insert({
      'merchant_id': merchantId,
      'movement_type': movementType,
      'balance_effect': balanceEffect,
      'amount': amount,
      'currency': currency,
      'movement_date':
          '${movementDate.year.toString().padLeft(4, '0')}-'
          '${movementDate.month.toString().padLeft(2, '0')}-'
          '${movementDate.day.toString().padLeft(2, '0')}',
      'notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
    });
  }

  Future<void> deleteLedgerMovement(int id) async {
    await _db.from('merchant_ledger').delete().eq('id', id);
  }

  Future<void> updateLedgerMovement({
    required int id,
    required String movementType,
    required int balanceEffect,
    required double amount,
    required String currency,
    required DateTime movementDate,
    String? notes,
  }) async {
    await _db.from('merchant_ledger').update({
      'movement_type': movementType,
      'balance_effect': balanceEffect,
      'amount': amount,
      'currency': currency,
      'movement_date':
          '${movementDate.year.toString().padLeft(4, '0')}-'
          '${movementDate.month.toString().padLeft(2, '0')}-'
          '${movementDate.day.toString().padLeft(2, '0')}',
      'notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
