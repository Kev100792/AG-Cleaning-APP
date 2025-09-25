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
  List<String> _typeOptions = const ['PRO', 'PARTICULIER'];
  bool _loading = false;
  bool _initLoading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final types = await _svc.getClientTypesOrFallback();
      setState(() => _typeOptions = types);

      if (widget.clientId != null) {
        final c = await _svc.getById(widget.orgId, widget.clientId!);
        if (c != null) {
          _nameCtrl.text = c['name'] ?? '';
          _vatCtrl.text = c['vat'] ?? '';
          _emailCtrl.text = c['email'] ?? '';
          _phoneCtrl.text = c['phone'] ?? '';
          _clientType = c['client_type'] ?? (_typeOptions.isNotEmpty ? _typeOptions.first : null);
        }
      } else {
        _clientType = _typeOptions.isNotEmpty ? _typeOptions.first : null;
      }
    } catch (e) {
      _showSnack('Erreur lors du chargement: $e', isError: true);
    } finally {
      if (mounted) setState(() => _initLoading = false);
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

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : null),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'org_id': widget.orgId,
      'name': _nameCtrl.text.trim(),
      'client_type': _clientType,
      'vat': _vatCtrl.text.trim().isEmpty ? null : _vatCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    };

    setState(() => _loading = true);
    try {
      Map<String, dynamic>? saved;
      if (widget.clientId == null) {
        saved = await _svc.create(payload);
      } else {
        saved = await _svc.update(widget.clientId!, payload);
      }

      _showSnack('Client sauvegardé');
      widget.onSaved?.call(saved ?? payload);
      if (mounted) Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      _showSnack(e.message ?? 'Erreur Supabase', isError: true);
    } catch (e) {
      _showSnack('Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null;
  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return r.hasMatch(v.trim()) ? null : 'Email invalide';
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clientId == null ? 'Nouveau client' : 'Modifier le client'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _save,
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: _initLoading
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
              absorbing: _loading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nom
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom du client',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        validator: _required,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      // Type (DropdownMenu M3 -> initialSelection)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DropdownMenu<String>(
                          initialSelection: _clientType ?? (_typeOptions.isNotEmpty ? _typeOptions.first : null),
                          onSelected: (v) => setState(() => _clientType = v),
                          dropdownMenuEntries: _typeOptions
                              .map((t) => DropdownMenuEntry<String>(value: t, label: t))
                              .toList(),
                          label: const Text('Type de client'),
                          leadingIcon: const Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // TVA
                      TextFormField(
                        controller: _vatCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de TVA (optionnel)',
                          prefixIcon: Icon(Icons.receipt_long_outlined),
                        ),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\.\- ]'))],
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email (optionnel)',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _emailValidator,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      // Téléphone
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone (optionnel)',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-(). ]'))],
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
