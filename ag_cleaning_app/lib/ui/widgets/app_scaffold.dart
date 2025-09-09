import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';

class AppScaffold extends StatelessWidget {
  final String currentPath;
  final Widget child;
  const AppScaffold({super.key, required this.currentPath, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Header gradient + Material (pour les boutons Ink ripple)
    final header = Material(
      type: MaterialType.transparency,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: 0.12),
              scheme.secondary.withValues(alpha: 0.10),
              scheme.tertiary.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text('AG Cleaning – CRM', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => context.go(Routes.interventions),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle intervention'),
                )
              ],
            ),
          ),
        ),
      ),
    );

    final items = <_NavItem>[
      _NavItem('Tableau de bord', Icons.dashboard_outlined, Routes.dashboard),
      _NavItem('Clients', Icons.people_alt_outlined, Routes.clients),
      _NavItem('Chantiers', Icons.engineering_outlined, Routes.chantiers),
      _NavItem('Interventions', Icons.event_available_outlined, Routes.interventions),
      _NavItem('Opportunités', Icons.trending_up_outlined, Routes.opportunites),
      _NavItem('Devis & Factures', Icons.receipt_long_outlined, Routes.devisFactures),
      _NavItem('Contrats & Docs', Icons.folder_open_outlined, Routes.contratsDocs),
      _NavItem('Paramètres', Icons.settings_outlined, Routes.settings),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1100;
        if (wide) {
          final selectedIndex = items.indexWhere((e) => e.route == currentPath);
          return Column(
            children: [
              header,
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Rail sous Material pour gérer les effets d’encre
                    Material(
                      color: Colors.white,
                      child: SizedBox(
                        width: 240,
                        child: NavigationRail(
                          selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                          groupAlignment: -0.9,
                          labelType: NavigationRailLabelType.all,
                          destinations: [
                            for (final e in items)
                              NavigationRailDestination(
                                icon: Icon(e.icon),
                                selectedIcon: Icon(e.icon),
                                label: Text(e.label),
                              ),
                          ],
                          onDestinationSelected: (i) => context.go(items[i].route),
                        ),
                      ),
                    ),
                    // Contenu
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _ElevatedPanel(child: child),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // Mobile: le Scaffold fournit déjà le Material parent
        final currentIndex = items.indexWhere((e) => e.route == currentPath).clamp(0, items.length - 1);
        return Scaffold(
          body: Column(
            children: [
              header,
              Expanded(child: Padding(padding: const EdgeInsets.all(12), child: child)),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            destinations: [for (final e in items) NavigationDestination(icon: Icon(e.icon), label: e.label)],
            onDestinationSelected: (i) => context.go(items[i].route),
          ),
        );
      },
    );
  }
}

class _ElevatedPanel extends StatelessWidget {
  final Widget child;
  const _ElevatedPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material( // Material parent pour tout le contenu
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  _NavItem(this.label, this.icon, this.route);
}
