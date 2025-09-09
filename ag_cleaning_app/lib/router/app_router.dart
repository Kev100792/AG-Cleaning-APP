import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ui/widgets/app_scaffold.dart';
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
import '../features/orgs/org_state.dart';
import '../features/orgs/org_create_page.dart';

class Routes {
  static const dashboard = '/';
  static const login = '/login';
  static const selectOrg = '/select-org';
  static const clients = '/clients';
  static const chantiers = '/chantiers';
  static const interventions = '/interventions';
  static const opportunites = '/opportunites';
  static const devisFactures = '/devis-factures';
  static const contratsDocs = '/contrats-docs';
  static const settings = '/parametres';
}

class AppRouter {
  static final router = GoRouter(
    initialLocation: Routes.dashboard,
    refreshListenable: AuthListenable(),
    redirect: (ctx, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loggedIn = session != null;
      final goingLogin = state.matchedLocation == Routes.login;
      if (!loggedIn && !goingLogin) return Routes.login;
      if (loggedIn && goingLogin) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        name: 'login',
        pageBuilder: (ctx, st) => _page(const LoginPage()),
      ),
      GoRoute(
        path: Routes.selectOrg,
        name: 'selectOrg',
        pageBuilder: (ctx, st) => _page(const OrgSelectorPage()),
      ),
      GoRoute(
        path: '/orgs/create',
        name: 'orgCreate',
        pageBuilder: (ctx, st) => _page(const OrgCreatePage()),
      ),
      GoRoute(
        path: Routes.dashboard,
        name: 'dashboard',
        pageBuilder: (ctx, st) => _page(
          AppScaffold(
            currentPath: Routes.dashboard,
            child: const DashboardPage(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.clients,
        name: 'clients',
        pageBuilder: (ctx, st) => _page(
          AppScaffold(currentPath: Routes.clients, child: const ClientsPage()),
        ),
      ),
      GoRoute(
        path: Routes.chantiers,
        name: 'chantiers',
        pageBuilder: (ctx, st) => _page(
          AppScaffold(
            currentPath: Routes.chantiers,
            child: const ChantiersPage(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.interventions,
        name: 'interventions',
        pageBuilder: (ctx, st) => _page(
          AppScaffold(
            currentPath: Routes.interventions,
            child: const InterventionsPage(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.opportunites,
        name: 'opportunites',
        pageBuilder: (ctx, st) => _page(
          AppScaffold(
            currentPath: Routes.opportunites,
            child: const OpportunitesPage(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.devisFactures,
        name: 'devis_factures',
        pageBuilder: (ctx, st) => _page(
          AppScaffold(
            currentPath: Routes.devisFactures,
            child: const DevisFacturesPage(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.contratsDocs,
        name: 'contrats_docs',
        pageBuilder: (ctx, st) => _page(
          AppScaffold(
            currentPath: Routes.contratsDocs,
            child: const ContratsDocsPage(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'parametres',
        pageBuilder: (ctx, st) => _page(
          AppScaffold(
            currentPath: Routes.settings,
            child: const SettingsPage(),
          ),
        ),
      ),
    ],
    errorPageBuilder: (ctx, st) => _page(
      AppScaffold(currentPath: Routes.dashboard, child: const DashboardPage()),
    ),
  );

  static CustomTransitionPage _page(Widget child) => CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
