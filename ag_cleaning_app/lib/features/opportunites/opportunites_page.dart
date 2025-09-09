import 'package:flutter/material.dart';

class OpportunitesPage extends StatelessWidget {
  const OpportunitesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stages = [
      'Nouveau',
      'Qualifié',
      'Visite planifiée',
      'Proposition',
      'Contrat',
      'À planifier',
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opportunités',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: stages
                  .map(
                    (s) => Expanded(
                      child: Card(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                s,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: 3,
                                itemBuilder: (_, i) => Card(
                                  child: ListTile(
                                    title: Text('Prospect ${i + 1}'),
                                    subtitle: const Text('Détails à venir'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
