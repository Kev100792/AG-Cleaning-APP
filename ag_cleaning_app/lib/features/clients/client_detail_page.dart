import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'clients_service.dart';
import 'client_form_page.dart';

class ClientDetailPage extends StatefulWidget {
  final String orgId;
  final String clientId;

  const ClientDetailPage({
    super.key,
    required this.orgId,
    required this.clientId,
  });

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  final _svc = ClientsService();
  Map<String, dynamic>? _client;
  Map<String, int>? _stats;
  List<Map<String, dynamic>> _sites = [];
  List<Map<String, dynamic>> _chantiers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = await _svc.fetchClientById(widget.orgId, widget.clientId);
      if (client == null) {
        setState(() {
          _error = "Client introuvable.";
          _loading = false;
        });
        return;
      }
      final stats = await _svc.fetchClientStats(widget.orgId, widget.clientId);
      final sites = await _svc.fetchSitesPreview(widget.orgId, widget.clientId, limit: 5);
      final chantiers = await _svc.fetchChantiersPreview(widget.orgId, widget.clientId, limit: 5);

      setState(() {
        _client = client;
        _stats = stats;
        _sites = sites;
        _chantiers = chantiers;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Erreur lors du chargement : $e";
        _loading = false;
      });
    }
  }

  void _goEdit() async {
    if (_client == null) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClientFormPage(
        orgId: widget.orgId,
        clientId: widget.clientId,
        onSaved: (updated) {
          // Après sauvegarde, on rafraîchit les données
          _load();
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail client'),
        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit),
            onPressed: _client == null ? null : _goEdit,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _client == null
                  ? const Center(child: Text('Aucune donnée'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeaderCard(client: _client!),
                            const SizedBox(height: 12),
                            _StatsRow(stats: _stats ?? {'sites': 0, 'chantiers': 0}),
                            const SizedBox(height: 16),
                            _SectionTitle(
                              title: 'Sites récents',
                              onSeeAll: () {
                                // plus tard : naviguer vers la liste de tous les sites du client
                              },
                            ),
                            const SizedBox(height: 8),
                            _SitesList(items: _sites),
                            const SizedBox(height: 16),
                            _SectionTitle(
                              title: 'Chantiers récents',
                              onSeeAll: () {
                                // plus tard : naviguer vers la liste complète des chantiers
                              },
                            ),
                            const SizedBox(height: 8),
                            _ChantiersList(items: _chantiers),
                            const SizedBox(height: 32),
                            _MetaInfo(client: _client!),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.client});
  final Map<String, dynamic> client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = client['name'] ?? '—';
    final type = client['client_type'] ?? '—'; // 'PRO' | 'PARTICULIER' (à confirmer selon ton schéma)
    final vat = client['vat'] ?? '';
    final email = client['email'] ?? '';
    final phone = client['phone'] ?? '';
    final address1 = client['address_line1'] ?? '';
    final postal = client['postal_code']?.toString() ?? '';
    final city = client['city'] ?? '';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Chip(text: type == 'PRO' ? 'Professionnel' : 'Particulier', icon: Icons.badge_outlined),
                    if (vat.isNotEmpty) _Chip(text: 'TVA: $vat', icon: Icons.receipt_long_outlined),
                    if (email.isNotEmpty) _Chip(text: email, icon: Icons.email_outlined),
                    if (phone.isNotEmpty) _Chip(text: phone, icon: Icons.phone_outlined),
                  ],
                ),
                if (address1.isNotEmpty || city.isNotEmpty || postal.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: 6),
                      Expanded(child: Text('$address1, $postal $city')),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final Map<String, int> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: _StatBox(label: 'Sites', value: stats['sites'] ?? 0, icon: Icons.apartment_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _StatBox(label: 'Chantiers', value: stats['chantiers'] ?? 0, icon: Icons.work_outline)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withOpacity(.4)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          )
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
        if (onSeeAll != null)
          TextButton.icon(onPressed: onSeeAll, icon: const Icon(Icons.list_alt_outlined, size: 18), label: const Text('Voir tout')),
      ],
    );
  }
}

class _SitesList extends StatelessWidget {
  const _SitesList({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyBox(text: 'Aucun site pour le moment.');
    }
    return Column(
      children: items.map((e) {
        final name = e['name'] ?? '—';
        final city = e['city'] ?? '';
        final postal = e['postal_code']?.toString() ?? '';
        final addr = e['address_line1'] ?? '';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.apartment_outlined),
            title: Text(name),
            subtitle: Text('$addr, $postal $city'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: naviguer vers le détail du site
            },
          ),
        );
      }).toList(),
    );
  }
}

class _ChantiersList extends StatelessWidget {
  const _ChantiersList({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyBox(text: 'Aucun chantier pour le moment.');
    }
    return Column(
      children: items.map((e) {
        final title = e['title'] ?? '—';
        final status = e['status'] ?? '—';
        final siteName = e['sites']?['name'] ?? '';
        final city = e['sites']?['city'] ?? '';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.work_outline),
            title: Text(title),
            subtitle: Text('$siteName • $city'),
            trailing: Text(status, style: const TextStyle(fontSize: 12)),
            onTap: () {
              // TODO: naviguer vers le détail chantier
            },
          ),
        );
      }).toList(),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  const _MetaInfo({required this.client});
  final Map<String, dynamic> client;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final createdAt = client['created_at'] != null ? df.format(DateTime.parse(client['created_at'])) : '—';
    final updatedAt = client['updated_at'] != null ? df.format(DateTime.parse(client['updated_at'])) : '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle.merge(
          style: const TextStyle(fontSize: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Métadonnées', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Créé le : $createdAt'),
              Text('Modifié le : $updatedAt'),
              if (client['created_by'] != null) Text('Créé par : ${client['created_by']}'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.3)),
      ),
      child: Text(text),
    );
  }
}
