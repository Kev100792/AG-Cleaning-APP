import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'org_state.dart';
import 'package:go_router/go_router.dart';

class OrgSelectorPage extends ConsumerStatefulWidget {
  const OrgSelectorPage({super.key});
  @override
  ConsumerState<OrgSelectorPage> createState() => _OrgSelectorPageState();
}

class _OrgSelectorPageState extends ConsumerState<OrgSelectorPage> {
  final nameCtrl = TextEditingController();
  bool creating = false;

  @override
  Widget build(BuildContext context) {
    final orgs = ref.watch(orgMembershipsProvider).value ?? [];
    final current = ref.watch(currentOrgIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sélection d’organisation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (orgs.isNotEmpty) ...[
              Text(
                'Vos organisations',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...orgs.map((m) {
                final orgId = m['org_id'] as String;
                final name = (m['orgs'] as Map)['name'] as String;
                final role = m['role'] as String;
                final selected = current == orgId;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0] : '?'),
                  ),
                  title: Text(name),
                  subtitle: Text('Rôle: $role'),
                  trailing: selected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    ref.read(currentOrgIdProvider.notifier).state = orgId;
                    Navigator.of(context).maybePop();
                  },
                );
              }),
              const Divider(height: 32),
            ],
            Text(
              'Créer une organisation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de l’organisation (rapide)',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.add_business),
              label: Text(creating ? '...' : 'Créer et utiliser'),
              onPressed: creating
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final nav = Navigator.of(
                        context,
                      ); // <-- capture AVANT await
                      setState(() => creating = true);
                      try {
                        final id = await createOrganization(
                          nameCtrl.text.trim(),
                        );
                        ref.invalidate(orgMembershipsProvider);
                        ref.read(currentOrgIdProvider.notifier).state = id;
                        nav.maybePop();
                      } finally {
                        if (mounted) setState(() => creating = false);
                      }
                    },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => GoRouter.of(context).push('/orgs/create'),
              icon: const Icon(Icons.settings_suggest),
              label: const Text('Création détaillée…'),
            ),
          ],
        ),
      ),
    );
  }
}
