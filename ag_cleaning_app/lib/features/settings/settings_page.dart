import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/widgets/slide_over.dart';
import '../orgs/org_edit_sheet.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('Paramètres', style: text.headlineLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.apartment_outlined, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Organisation', style: text.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          'Nom, adresse, juridique, fuseau horaire, TVA…',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => showSlideOver(
                      context: context,
                      title: 'Éditer l’organisation',
                      builder: (_) => const OrgEditSheet(),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // tu pourras ajouter d’autres cartes (Branding, Intégrations, Utilisateurs…)
        ],
      ),
    );
  }
}
