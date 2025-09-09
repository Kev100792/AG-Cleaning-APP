import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'clients_service.dart';

class ClientFormPage extends StatefulWidget {
  final String orgId;
  final String? clientId;
  final void Function(Map<String, dynamic> client)? onSaved;

  const ClientFormPage({
    super.key,
    required this.orgId,
    this.clientId,
    this.onSaved,
  });

  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _svc = ClientsService();

  final _nameCtrl = TextEditingController();
  final _vatCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String? _clientType;
  bool _loading = false;
  List<String> _typeOptions = const ['PRO', 'PART'];

  @override
  void initState() {
    super.initState();
    _loadTypeOptions();
    if (widget.clientId != null) {
      _loadClient(widget.clientId!);
    }
  }

  Future<void> _loadTypeOptions() async {
    try {
      final opts = await _svc.getClientTypesOrFallback();
      if (mounted) {
        setState(() {
          _typeOptions = opts;
          _clientType ??= opts.first;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadClient(String id) async {
    setState(() => _loading = true);
    try {
      final c = await _svc.getById(id);
      if (c != null) {
        _nameCtrl.text = c['name'] ?? '';
        _vatCtrl.text = c['vat'] ?? '';
        _emailCtrl.text = c['billing_email'] ?? '';
        _phoneCtrl.text = c['phone'] ?? '';
        _clientType = c['type']?.toString() ?? _typeOptions.first;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vatCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nom du client requis';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final emailRx = RegExp(r"^[^\\s@]+@[^\\s@]+\\.[^\\s@]+\$");
    if (!emailRx.hasMatch(v.trim())) return 'Email invalide';
    return null;
  }

  Future<void> _save() async {
    final form = _formKey.currentState!;
    if (!form.validate()) return;

    final name = _nameCtrl.text.trim();
    final vat = _vatCtrl.text.trim().isEmpty ? null : _vatCtrl.text.trim();
    final billingEmail = _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();
    final type = _clientType ?? _typeOptions.first;

    setState(() => _loading = true);
    try {
      Map<String, dynamic> saved;
      if (widget.clientId == null) {
        saved = await _svc.create(
          orgId: widget.orgId,
          type: type,
          name: name,
          vat: vat,
          billingEmail: billingEmail,
          phone: phone,
          meta: null,
        );
        _showSnack('Client créé avec succès');
      } else {
        saved = await _svc.update(widget.clientId!, {
          'type': type,
          'name': name,
          'vat': vat,
          'billing_email': billingEmail,
          'phone': phone,
        });
        _showSnack('Client mis à jour');
      }

      widget.onSaved?.call(saved);
      if (mounted) Navigator.of(context).maybePop(saved);
    } on PostgrestException catch (e) {
      _showSnack(e.message ?? 'Erreur Supabase', isError: true);
    } catch (e) {
      _showSnack('Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.clientId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier le client' : 'Nouveau client'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _save,
            icon: const Icon(Icons.save),
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _loading,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _clientType ?? (_typeOptions.isNotEmpty ? _typeOptions.first : null),
                      items: _typeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _clientType = v),
                      decoration: const InputDecoration(labelText: 'Type de client', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nom / Raison sociale *', border: OutlineInputBorder()),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _vatCtrl,
                      decoration: const InputDecoration(labelText: 'TVA', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email de facturation', border: OutlineInputBorder()),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _save,
                        icon: const Icon(Icons.check),
                        label: Text(isEdit ? 'Enregistrer' : 'Créer le client'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x11000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
