import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/orgs/org_state.dart';

final clientsSearchProvider = StateProvider<String>((_) => '');

final clientsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  final search = ref.watch(clientsSearchProvider); // déclenche les rebuilds
  if (orgId == null) return [];

  var query = Supabase.instance.client
      .from('clients')
      .select('id, name, type, vat, billing_email, phone')
      .eq('org_id', orgId);

  if (search.trim().isNotEmpty) {
    query = query.ilike('name', '%${search.trim()}%');
  }

  final res = await query.order('name');
  final list = (res as List);
  return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

Future<Map<String, dynamic>> createClient({
  required String orgId,
  required String name,
  String? type,
  String? email,
  String? phone,
  String? vat,
}) async {
  final data = await Supabase.instance.client
      .from('clients')
      .insert({
        'org_id': orgId,
        'name': name,
        if (type != null) 'type': type,
        if (email != null) 'billing_email': email,
        if (phone != null) 'phone': phone,
        if (vat != null) 'vat': vat,
      })
      .select()
      .single();
  return Map<String, dynamic>.from(data as Map);
}
