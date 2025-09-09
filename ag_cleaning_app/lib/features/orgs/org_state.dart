import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final currentOrgIdProvider = StateProvider<String?>((_) => null);

bool isSuperAdminUser(User? u) {
  final md = u?.appMetadata; // Map<String, dynamic>?
  final roles = (md != null ? md['roles'] : null);
  if (roles is List) {
    return roles.map((e) => e.toString()).contains('super_admin');
  }
  return false;
}

/// Liste des organisations accessibles par l'utilisateur courant.
/// - user normal  : orgs via org_members (2 requêtes, sans embed)
/// - super_admin  : toutes les orgs
final orgMembershipsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final supa = Supabase.instance.client;
  final user = supa.auth.currentUser;
  if (user == null) return [];

  // super admin : toutes les orgs (simple)
  if (isSuperAdminUser(user)) {
    final rows = await supa.from('orgs').select('id,name').order('created_at');
    return (rows as List)
        .map<Map<String, dynamic>>(
          (o) => {
            'org_id': o['id'],
            'role': 'SUPER_ADMIN',
            'orgs': {'id': o['id'], 'name': o['name']},
          },
        )
        .toList();
  }

  // 1) on lit les memberships (sans embed)
  final mRows = await supa
      .from('org_members')
      .select('org_id, role')
      .eq('user_id', user.id)
      .isFilter('deleted_at', null)
      .order('created_at');

  // 1) memberships (déjà fait au-dessus)
  final memberships = (mRows as List).cast<Map<String, dynamic>>();
  if (memberships.isEmpty) return [];

  // 2) IDs uniques et non nuls
  final ids = {
    for (final m in memberships) (m['org_id'] as String?),
  }.whereType<String>().toList();

  if (ids.isEmpty) return [];

  // 3) Récupère les orgs (compat v2.9.0)
  // - si 1 id -> eq()
  // - si >1 id -> or('id.eq....,id.eq....')
  List<Map<String, dynamic>> orgRows;
  if (ids.length == 1) {
    final rows = await supa.from('orgs').select('id,name').eq('id', ids.first);
    orgRows = (rows as List).cast<Map<String, dynamic>>();
  } else {
    final orCond = ids.map((id) => 'id.eq.$id').join(',');
    final rows = await supa.from('orgs').select('id,name').or(orCond);
    orgRows = (rows as List).cast<Map<String, dynamic>>();
  }

  // 4) Map id -> org
  final orgs = <String, Map<String, dynamic>>{
    for (final o in orgRows) o['id'] as String: o,
  };

  // 5) shape homogène pour l’UI (et fallback si org non trouvée)
  return memberships.map<Map<String, dynamic>>((m) {
    final oid = m['org_id'] as String;
    final o = orgs[oid] ?? {'id': oid, 'name': 'Organisation'};
    return {
      'org_id': oid,
      'role': m['role'],
      'orgs': {'id': o['id'], 'name': o['name']},
    };
  }).toList();
});

/// Crée une organisation et renvoie son id (l'RPC doit aussi créer l'org_members OWNER).
Future<String> createOrganization(String name) async {
  final supa = Supabase.instance.client;
  final res = await supa.rpc('create_organization', params: {'p_name': name});
  return res as String;
}
