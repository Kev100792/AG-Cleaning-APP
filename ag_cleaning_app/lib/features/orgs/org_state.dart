import 'dart:async'; // <-- nécessaire pour StreamSubscription
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supa = Supabase.instance.client;

/// Session courante (écoute les changements d'auth)
final sessionProvider = StreamProvider<Session?>((ref) async* {
  yield supa.auth.currentSession;
  yield* supa.auth.onAuthStateChange.map((e) => e.session);
});

/// Notifie GoRouter quand l'auth change
class AuthListenable extends ChangeNotifier {
  AuthListenable() {
    _sub = supa.auth.onAuthStateChange.listen((_) => notifyListeners());
  }
  late final StreamSubscription _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final authListenableProvider = Provider((_) => AuthListenable());

/// Organisation courante (multi-tenant)
final currentOrgIdProvider = StateProvider<String?>((_) => null);

/// Liste des organisations où l'utilisateur est membre
final orgMembershipsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = supa.auth.currentUser;
  if (user == null) return [];
  final res = await supa
      .from('org_members')
      .select('org_id, role, orgs!inner(name)')
      .eq('user_id', user.id)
      .eq('is_active', true)
      .order('org_id');
  return (res as List).cast<Map<String, dynamic>>();
});

/// RPC pour créer une org et t'y ajouter comme admin
Future<String> createOrganization(String name) async {
  final data = await supa.rpc(
    'create_organization',
    params: {'p_name': name, 'p_vat': null, 'p_address': null},
  );
  return data as String;
}
