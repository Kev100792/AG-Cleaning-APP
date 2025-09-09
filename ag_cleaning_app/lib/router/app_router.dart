import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/widgets/app_scaffold.dart';
import '../ui/widgets/org_gate.dart';

import '../features/dashboard/dashboard_page.dart';
import '../features/clients/clients_page.dart';
import '../features/chantiers/chantiers_page.dart';
import '../features/interventions/interventions_page.dart';
import '../features/opportunites/opportunites_page.dart';
import '../features/devis_factures/devis_factures_page.dart';
import '../features/contrats_docs/contrats_docs_page.dart';
import '../features/settings/settings_page.dart';

import '../features/auth/login_page.dart';
import '../features/orgs/org_selector_page.dart';
import '../features/orgs/org_create_page.dart';

class Routes {
  static const dashboard = '/';
  static const clients = '/clients';
  static const chantiers = '/chantiers';
  static const interventions = '/interventions';
  static const opportunites = '/opportunites';
  static const devisFactures = '/devis-factures';
  static const contratsDocs = '/contrats-docs';
  static const settings = '/settings';

  static const login = '/login';
  static const selectOrg = '/select-org';
  static const createOrg = '/orgs/create';
}

Page _page(Widget child) => MaterialPage(child: child);

final appRouter = GoRouter(
  initialLocation: Routes.dashboard,
  routes: [
    // Libres (pas d'OrgGate)
    GoRoute(
      path: Routes.login,
      pageBuilder: (_, __) => _page(const LoginPage()),
    ),
    GoRoute(
      path: Routes.selectOrg,
      pageBuilder: (ctx, st) => _page(const OrgSelectorPage()),
    ),
    GoRoute(
      path: Routes.createOrg,
      pageBuilder: (ctx, st) => _page(const OrgCreatePage()),
    ),

    // Protégés (OrgGate)
    GoRoute(
      path: Routes.dashboard,
      pageBuilder: (ctx, st) => _page(
        AppScaffold(currentPath: Routes.dashboard, child: const OrgGate(child: DashboardPage())),
      ),
    ),
    GoRoute(
      path: Routes.clients,
      pageBuilder: (ctx, st) => _page(
        AppScaffold(currentPath: Routes.clients, child: const OrgGate(child: ClientsPage())),
      ),
    ),
    GoRoute(
      path: Routes.chantiers,
      pageBuilder: (ctx, st) => _page(
        AppScaffold(currentPath: Routes.chantiers, child: const OrgGate(child: ChantiersPage())),
      ),
    ),
    GoRoute(
      path: Routes.interventions,
      pageBuilder: (ctx, st) => _page(
        AppScaffold(currentPath: Routes.interventions, child: const OrgGate(child: InterventionsPage())),
      ),
    ),
    GoRoute(
      path: Routes.opportunites,
      pageBuilder: (ctx, st) => _page(
        AppScaffold(currentPath: Routes.opportunites, child: const OrgGate(child: OpportunitesPage())),
      ),
    ),
    GoRoute(
      path: Routes.devisFactures,
      pageBuilder: (ctx, st) => _page(
        AppScaffold(currentPath: Routes.devisFactures, child: const OrgGate(child: DevisFacturesPage())),
      ),
    ),
    GoRoute(
      path: Routes.contratsDocs,
      pageBuilder: (ctx, st) => _page(
        AppScaffold(currentPath: Routes.contratsDocs, child: const OrgGate(child: ContratsDocsPage())),
      ),
    ),
    GoRoute(
      path: Routes.settings,
      pageBuilder: (ctx, st) => _page(
        AppScaffold(currentPath: Routes.settings, child: const OrgGate(child: SettingsPage())),
      ),
    ),
  ],
);
