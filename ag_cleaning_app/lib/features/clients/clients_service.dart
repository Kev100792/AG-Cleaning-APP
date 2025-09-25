import 'package:supabase_flutter/supabase_flutter.dart';

class ClientsService {
  final SupabaseClient _sb = Supabase.instance.client;

  // ---- ALIAS pour compatibilité avec client_detail_page ----
  Future<Map<String, dynamic>?> fetchClientById(String orgId, String clientId) {
    return getById(orgId, clientId);
  }

  // ---- DÉTAIL ----
  Future<Map<String, dynamic>?> getById(String orgId, String clientId) async {
    final data = await _sb
        .from('clients')
        .select()
        .eq('org_id', orgId)
        .eq('id', clientId)
        .maybeSingle();
    return data;
  }

  // ---- CRÉATION ----
  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    if (payload['org_id'] == null) {
      throw ArgumentError('org_id est requis pour créer un client.');
    }
    final res = await _sb.from('clients').insert(payload).select().single();
    return (res as Map<String, dynamic>);
  }

  // ---- MISE À JOUR ----
  Future<Map<String, dynamic>?> update(String clientId, Map<String, dynamic> patch) async {
    final res = await _sb
        .from('clients')
        .update(patch)
        .eq('id', clientId)
        .select()
        .maybeSingle();
    return res;
  }

  // ---- OPTIONS TYPE CLIENT ----
  Future<List<String>> getClientTypesOrFallback() async {
    try {
      final rows = await _sb.from('client_types').select('code').order('code');
      if (rows is List && rows.isNotEmpty) {
        return rows
            .map((e) => (e['code'] as String).trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // table absente → fallback
    }
    return const ['PRO', 'PARTICULIER'];
  }

  // ---- STATS / PREVIEWS (simple et robuste) ----
  Future<Map<String, int>> fetchClientStats(String orgId, String clientId) async {
    final sites = await _sb
        .from('sites')
        .select('id')
        .eq('org_id', orgId)
        .eq('client_id', clientId);

    final chantiers = await _sb
        .from('chantiers')
        .select('id, sites!inner(client_id)')
        .eq('org_id', orgId)
        .eq('sites.client_id', clientId);

    return {
      'sites': (sites as List).length,
      'chantiers': (chantiers as List).length,
    };
  }

  Future<List<Map<String, dynamic>>> fetchSitesPreview(
    String orgId,
    String clientId, {
    int limit = 5,
  }) async {
    final res = await _sb
        .from('sites')
        .select('id,name,city,postal_code,address_line1')
        .eq('org_id', orgId)
        .eq('client_id', clientId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchChantiersPreview(
    String orgId,
    String clientId, {
    int limit = 5,
  }) async {
    final res = await _sb
        .from('chantiers')
        .select('id,title,status,site_id,sites!inner(name,city)')
        .eq('org_id', orgId)
        .eq('sites.client_id', clientId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (res as List).cast<Map<String, dynamic>>();
  }

  // ---- LISTE paginée + recherche ----
  Future<List<Map<String, dynamic>>> list({
    required String orgId,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    var q = _sb
        .from('clients')
        .select('id,name,client_type,email,phone,vat,created_at')
        .eq('org_id', orgId);

    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      // IMPORTANT: or() avant order()
      q = q.or('name.ilike.$s,email.ilike.$s,vat.ilike.$s,phone.ilike.$s');
    }

    final res = await q.order('created_at', ascending: false).range(
          offset,
          offset + limit - 1,
        );
    return (res as List).cast<Map<String, dynamic>>();
  }
}
