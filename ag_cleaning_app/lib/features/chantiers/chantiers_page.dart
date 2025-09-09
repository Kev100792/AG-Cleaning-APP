import 'package:flutter/material.dart';

class ChantiersPage extends StatelessWidget {
  const ChantiersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chantiers', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Rechercher un chantier...',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Nouveau chantier'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: 10,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text('Chantier #${i + 1}'),
                  subtitle: const Text('Adresse — (données à venir)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {}, // TODO: fiche chantier
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
