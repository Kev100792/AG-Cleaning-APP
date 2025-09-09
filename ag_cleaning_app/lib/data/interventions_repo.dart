import 'package:flutter/material.dart'; // DateTimeRange
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/orgs/org_state.dart';

final calendarRangeProvider = StateProvider<DateTimeRange?>((_) => null);

final interventionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final orgId = ref.watch(currentOrgIdProvider);
      final range = ref.watch(calendarRangeProvider);
      if (orgId == null || range == null) return [];
      final res = await Supabase.instance.client
          .from('interventions')
          .select('id, chantier_id, starts_at, ends_at, status, assigned_to')
          .eq('org_id', orgId)
          .gte('starts_at', range.start.toUtc().toIso8601String())
          .lte('ends_at', range.end.toUtc().toIso8601String())
          .order('starts_at');
      final list = (res as List);
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });

Future<Map<String, dynamic>> createIntervention({
  required String orgId,
  required String chantierId,
  required DateTime startsAt,
  required DateTime endsAt,
  List<String>? assignedTo,
  String? notes,
}) async {
  final data = await Supabase.instance.client
      .from('interventions')
      .insert({
        'org_id': orgId,
        'chantier_id': chantierId,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      })
      .select()
      .single();
  return Map<String, dynamic>.from(data as Map);
}
