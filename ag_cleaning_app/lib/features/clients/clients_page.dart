import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/clients_repo.dart';
import '../orgs/org_state.dart';
import '../../router/app_router.dart';
import 'package:go_router/go_router.dart';

class ClientsPage extends ConsumerWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgId = ref.watch(currentOrgIdProvider);
    ref.watch(clientsSearchProvider); // on observe pour rebuild
    final clients = ref.watch(clientsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Clients',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              if (orgId == null)
                OutlinedButton.icon(
                  onPressed: () => context.push(Routes.selectOrg),
                  icon: const Icon(Icons.apartment),
                  label: const Text('Choisir une organisation'),
                ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: orgId == null
                    ? null
                    : () => _openCreateDialog(context, ref, orgId),
                icon: const Icon(Icons.add),
                label: const Text('Nouveau client'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Rechercher un client...',
                  ),
                  onChanged: (v) =>
                      ref.read(clientsSearchProvider.notifier).state = v,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push(Routes.selectOrg),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Organisation'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: clients.when(
                data: (list) => ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = list[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.business)),
                      title: Text(c['name'] ?? '—'),
                      subtitle: Text(
                        '${c['type'] ?? ''} ${c['billing_email'] ?? ''} ${c['phone'] ?? ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Erreur: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateDialog(
    BuildContext context,
    WidgetRef ref,
    String orgId,
  ) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final vat = TextEditingController();
    String type = 'PRO';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouveau client'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nom *'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: type, // <-- au lieu de value:
                items: const [
                  DropdownMenuItem(value: 'PRO', child: Text('PRO')),
                  DropdownMenuItem(
                    value: 'PARTICULIER',
                    child: Text('PARTICULIER'),
                  ),
                  DropdownMenuItem(value: 'SYNDIC', child: Text('SYNDIC')),
                ],
                onChanged: (v) => type = v ?? 'PRO',
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: email,
                decoration: const InputDecoration(
                  labelText: 'Email facturation',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: vat,
                decoration: const InputDecoration(labelText: 'TVA'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await createClient(
        orgId: orgId,
        name: name.text.trim(),
        type: type,
        email: email.text.trim().isEmpty ? null : email.text.trim(),
        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
        vat: vat.text.trim().isEmpty ? null : vat.text.trim(),
      );
      ref.invalidate(clientsProvider);
    }
  }
}
