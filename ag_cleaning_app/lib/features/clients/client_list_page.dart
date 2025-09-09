import 'package:flutter/material.dart';
import 'clients_service.dart';
import 'client_form_page.dart';

class ClientListPage extends StatefulWidget {
  final String orgId;

  const ClientListPage({super.key, required this.orgId});

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  final _svc = ClientsService();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  bool _initialLoaded = false;
  String? _search;
  int _offset = 0;
  final int _limit = 50;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetch(initial: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading) return;
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _fetch();
    }
  }

  Future<void> _fetch({bool initial = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (initial) {
        _offset = 0;
        _hasMore = true;
      }
    });
    try {
      final data = await _svc.list(
        orgId: widget.orgId,
        search: _search,
        limit: _limit,
        offset: _offset,
      );
      setState(() {
        if (initial) _items = [];
        _items.addAll(data);
        _offset += data.length;
        _hasMore = data.length == _limit;
        _initialLoaded = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _fetch(initial: true);
  }

  void _onCreate() async {
    final saved = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientFormPage(
          orgId: widget.orgId,
          onSaved: (client) {},
        ),
      ),
    );
    if (saved != null) {
      await _fetch(initial: true);
    }
  }

  void _onEdit(String clientId) async {
    final saved = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientFormPage(
          orgId: widget.orgId,
          clientId: clientId,
          onSaved: (client) {},
        ),
      ),
    );
    if (saved != null) {
      await _fetch(initial: true);
    }
  }

  void _onSearchChanged(String value) {
    _search = value.trim().isEmpty ? null : value.trim();
    // petite latence volontaire pour UX; ici on relance direct simplifié
    _fetch(initial: true);
  }

  Widget _buildItem(Map<String, dynamic> c) {
    final name = (c['name'] ?? '') as String;
    final type = (c['type'] ?? '') as String;
    final email = (c['billing_email'] ?? '') as String?;
    final phone = (c['phone'] ?? '') as String?;
    final vat = (c['vat'] ?? '') as String?;

    return ListTile(
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (type.isNotEmpty) 'Type: $type',
          if (vat != null && vat.isNotEmpty) 'TVA: $vat',
          if (email != null && email.isNotEmpty) 'Email: $email',
          if (phone != null && phone.isNotEmpty) 'Tel: $phone',
        ].join('  •  '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _onEdit(c['id'] as String),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ListView.separated(
      controller: _scrollCtrl,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final c = _items[index];
        return _buildItem(c);
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher (nom, email)…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: !_initialLoaded && _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Aucun client')),
                      SizedBox(height: 400), // pour permettre le pull-to-refresh
                    ],
                  )
                : list,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreate,
        child: const Icon(Icons.add),
      ),
    );
  }
}
