import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/widgets/slide_over.dart';
import '../orgs/org_edit_sheet.dart';
import '../orgs/org_contacts_sheet.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget card({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onPressed,
      String actionLabel = 'Ouvrir',
      IconData actionIcon = Icons.arrow_forward,
    }) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(actionIcon),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('Paramètres', style: text.headlineLarge),
          const SizedBox(height: 12),
          card(
            icon: Icons.apartment_outlined,
            title: 'Organisation',
            subtitle: 'Nom, adresse, juridique, fuseau horaire, TVA…',
            onPressed: () => showSlideOver(
              context: context,
              title: 'Éditer l’organisation',
              builder: (_) => const OrgEditSheet(),
            ),
            actionLabel: 'Modifier',
            actionIcon: Icons.edit,
          ),
          const SizedBox(height: 12),
          card(
            icon: Icons.contacts_outlined,
            title: 'Contacts de l’organisation',
            subtitle: 'Général, Facturation, Support, Ventes, RH…',
            onPressed: () => showSlideOver(
              context: context,
              title: 'Contacts de l’organisation',
              builder: (_) => const OrgContactsSheet(),
            ),
          ),
        ],
      ),
    );
  }
}
