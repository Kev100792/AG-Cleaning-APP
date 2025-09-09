import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget kpi(String title, String value, IconData icon, Color color) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.12),
                scheme.surfaceContainerHigh,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text.labelLarge!.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: text.headlineMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('Tableau de bord', style: text.headlineLarge),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.6,
            ),
            children: [
              kpi(
                'Interventions du jour',
                '12',
                Icons.event_available,
                scheme.primary,
              ),
              kpi(
                'Opportunités actives',
                '7',
                Icons.trending_up,
                scheme.secondary,
              ),
              kpi('Devis en attente', '4', Icons.receipt_long, scheme.tertiary),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activité récente', style: text.titleLarge),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.build_circle_outlined),
                    title: const Text(
                      'Intervention ajoutée – Chantier Rue de la Paix',
                    ),
                    subtitle: Text(
                      'Aujourd’hui 08:00 → 10:00',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.person_add_alt),
                    title: Text('Nouveau client – ImmoLux SPRL'),
                    subtitle: Text('Hier'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
