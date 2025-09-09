import 'package:flutter/material.dart';

class ContratsDocsPage extends StatelessWidget {
  const ContratsDocsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contrats & Documents',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.post_add_outlined),
                label: const Text('Nouveau contrat'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Importer document'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: 12,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text('Contrat / Doc #${i + 1}'),
                  subtitle: const Text('Client / Validité / Type'),
                  trailing: const Icon(Icons.more_horiz),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
