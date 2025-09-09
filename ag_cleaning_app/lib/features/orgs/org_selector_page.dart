import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';
import 'org_state.dart';

class OrgSelectorPage extends ConsumerWidget {
  const OrgSelectorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si une org est déjà active => on envoie au dashboard
    final current = ref.watch(currentOrgIdProvider);
    if (current != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(Routes.dashboard);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final memberships = ref.watch(orgMembershipsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sélectionner une organisation')),
      body: memberships.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (rows) {
          if (rows.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(Routes.createOrg);
            });
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, i) {
              final r = rows[i];
              final org = r['orgs'] as Map<String, dynamic>? ?? {};
              return ListTile(
                leading: const Icon(Icons.apartment_outlined),
                title: Text(org['name']?.toString() ?? 'Organisation'),
                subtitle: Text('Rôle: ${r['role'] ?? 'MEMBER'}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ref.read(currentOrgIdProvider.notifier).state =
                      r['org_id'] as String;
                  context.go(Routes.dashboard);
                },
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: rows.length,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(Routes.createOrg),
        icon: const Icon(Icons.add),
        label: const Text('Créer une organisation'),
      ),
    );
  }
}
