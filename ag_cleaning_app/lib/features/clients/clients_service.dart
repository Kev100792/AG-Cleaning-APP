import 'package:supabase_flutter/supabase_flutter.dart';

class ClientsService {
  final SupabaseClient _sb;

  ClientsService({SupabaseClient? client}) : _sb = client ?? Supabase.instance.client;

  Future<List<Map<String, dynamic>>> list({
    required String orgId,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final q = _sb.from('clients')
      .select()
      .eq('org_id', orgId)
      .order('name', ascending: true)
      .range(offset, offset + limit - 1);

    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      q.or('name.ilike.$s,billing_email.ilike.$s');
    }

    final res = await q;
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final res = await _sb.from('clients').select().eq('id', id).maybeSingle();
    return res;
  }

  Future<Map<String, dynamic>> create({
    required String orgId,
    required String type,
    required String name,
    String? vat,
    String? billingEmail,
    String? phone,
    Map<String, dynamic>? meta,
  }) async {
    final payload = {
      'org_id': orgId,
      'type': type,
      'name': name,
      'vat': vat,
      'billing_email': billingEmail,
      'phone': phone,
      'meta': meta,
    };

    final res = await _sb.from('clients').insert(payload).select().single();
    return res;
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> patch) async {
    final res = await _sb
        .from('clients')
        .update(patch..['updated_at'] = DateTime.now().toUtc().toIso8601String())
        .eq('id', id)
        .select()
        .single();
    return res;
  }

  Future<void> remove(String id) async {
    await _sb.from('clients').delete().eq('id', id);
  }

  Future<List<String>> getClientTypesOrFallback() async {
    try {
      final res = await _sb.rpc('get_client_types');
      final arr = (res as List).cast<String>();
      if (arr.isNotEmpty) return arr;
    } catch (_) {}
    return const ['PRO', 'PART'];
  }
}
