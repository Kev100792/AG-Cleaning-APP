import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/orgs/org_state.dart';

class OrgGate extends ConsumerWidget {
  final Widget child;
  const OrgGate({super.key, required this.child});

  void _postFrame(VoidCallback cb) {
    WidgetsBinding.instance.addPostFrameCallback((_) => cb());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _postFrame(() => GoRouter.of(context).go('/login'));
      return const Center(child: CircularProgressIndicator());
    }

    // Si déjà une org active -> on affiche la page
    final current = ref.watch(currentOrgIdProvider);
    if (current != null) return child;

    // Sinon, on observe les orgs accessibles
    final memberships = ref.watch(orgMembershipsProvider);

    return memberships.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 12),
                Text('Impossible de charger vos organisations.'),
                const SizedBox(height: 8),
                Text('$e', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(orgMembershipsProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        );
      },
      data: (rows) {
        if (rows.isEmpty) {
          // Aucune org -> créer
          _postFrame(() => GoRouter.of(context).go('/orgs/create'));
          return const Center(child: CircularProgressIndicator());
        }
        if (rows.length == 1) {
          // Auto-sélection
          final id = rows.first['org_id'] as String;
          _postFrame(() => ref.read(currentOrgIdProvider.notifier).state = id);
          return const Center(child: CircularProgressIndicator());
        }
        // Plusieurs -> sélecteur
        _postFrame(() => GoRouter.of(context).go('/select-org'));
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
