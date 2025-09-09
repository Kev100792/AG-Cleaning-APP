import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/orgs/org_state.dart';

final chantiersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final orgId = ref.watch(currentOrgIdProvider);
      if (orgId == null) return [];
      final res = await Supabase.instance.client
          .from('chantiers')
          .select('id, title, site_id')
          .eq('org_id', orgId)
          .order('title');
      final list = (res as List);
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
