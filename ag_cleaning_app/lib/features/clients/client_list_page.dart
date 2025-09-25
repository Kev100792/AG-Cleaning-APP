import 'package:flutter/material.dart';
import 'clients_service.dart';
import 'client_form_page.dart';
import 'client_detail_page.dart';

class ClientListPage extends StatefulWidget {
  final String orgId;
  const ClientListPage({super.key, required this.orgId});

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  final _svc = ClientsService();
  final _searchCtrl = TextEditingController();

  bool _loading = false;
  List<Map<String, dynamic>> _items = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _svc.list(orgId: widget.orgId, search: _search, limit: 50, offset: 0);
      setState(() => _items = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openCreate() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClientFormPage(
        orgId: widget.orgId,
        onSaved: (_) => _load(),
      ),
    ));
  }

  void _openDetail(Map<String, dynamic> c) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClientDetailPage(
        orgId: widget.orgId,
        clientId: c['id'] as String,
      ),
    ));
  }

  Widget _buildItem(Map<String, dynamic> c) {
    final name = (c['name'] ?? '—').toString();
    final type = (c['client_type'] ?? '').toString();
    final vat = (c['vat'] ?? '').toString();
    final email = (c['email'] ?? '').toString();
    final phone = (c['phone'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        leading: const Icon(Icons.business_outlined),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            if (type.isNotEmpty) 'Type: $type',
            if (vat.isNotEmpty) 'TVA: $vat',
            if (email.isNotEmpty) 'Email: $email',
            if (phone.isNotEmpty) 'Tel: $phone',
          ].join('  •  '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openDetail(c), // 👉 tap = fiche (lecture seule)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher un client (nom, email, TVA, téléphone)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer',
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                          _load();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (v) {
                setState(() => _search = v.trim());
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('Aucun client. Cliquez sur “Nouveau”.'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (_, i) => _buildItem(_items[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
