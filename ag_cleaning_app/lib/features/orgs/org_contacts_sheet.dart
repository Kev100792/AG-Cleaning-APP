import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'org_state.dart';

class OrgContactsSheet extends ConsumerStatefulWidget {
  const OrgContactsSheet({super.key});

  @override
  ConsumerState<OrgContactsSheet> createState() => _OrgContactsSheetState();
}

class _OrgContactsSheetState extends ConsumerState<OrgContactsSheet> {
  bool loading = true;
  bool saving = false;
  String? err;
  List<Map<String, dynamic>> contacts = [];

  static const kinds = <String>[
    'GENERAL',
    'BILLING',
    'SUPPORT',
    'SALES',
    'HR',
    'OPERATIONS',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      final orgId = ref.read(currentOrgIdProvider);
      if (orgId == null) throw 'Aucune organisation sélectionnée';
      final supa = Supabase.instance.client;
      final rows = await supa
          .from('org_contacts')
          .select()
          .eq('org_id', orgId)
          .isFilter('deleted_at', null)
          .order('primary_contact', ascending: false)
          .order('kind', ascending: true)
          .order('created_at', ascending: true);
      contacts = (rows as List).cast<Map<String, dynamic>>();
    } catch (e) {
      err = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _deleteContact(Map<String, dynamic> row) async {
    final supa = Supabase.instance.client;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer le contact ?'),
            content: Text('“${row['person_name'] ?? ''}” sera supprimé.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    try {
      setState(() => saving = true);
      await supa
          .from('org_contacts')
          .update({
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', row['id'] as String);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Contact supprimé.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? row}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _ContactDialog(initial: row, kinds: kinds),
    );
    if (result == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 84),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (err != null) ...[
                  Text(err!, style: TextStyle(color: scheme.error)),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Text('Contacts de l’organisation', style: text.titleLarge),
                    const SizedBox(width: 8),
                    Tooltip(
                      message:
                          'Contacts dédiés (Général, Facturation, Support...)',
                      child: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: saving ? null : () => _openEditor(),
                      icon: const Icon(Icons.add),
                      label: const Text('Nouveau contact'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: contacts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final row = contacts[i];
                        final primary =
                            (row['primary_contact'] ?? false) as bool;
                        final subtitle = <String>[
                          if ((row['email'] ?? '').toString().isNotEmpty)
                            row['email'],
                          if ((row['phone'] ?? '').toString().isNotEmpty)
                            row['phone'],
                        ].join(' • ');
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              ((row['person_name'] ?? '') as String).isNotEmpty
                                  ? (row['person_name'] as String)[0]
                                        .toUpperCase()
                                  : (row['kind'] as String)[0],
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(row['person_name'] ?? '—'),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  row['kind'] ?? '—',
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (primary) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.star_rounded,
                                  color: scheme.secondary,
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(subtitle.isEmpty ? '—' : subtitle),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Éditer',
                                onPressed: saving
                                    ? null
                                    : () => _openEditor(row: row),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                tooltip: 'Supprimer',
                                onPressed: saving
                                    ? null
                                    : () => _deleteContact(row),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ],
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Fermer'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: saving ? null : () => _openEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un contact'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initial;
  final List<String> kinds;
  const _ContactDialog({this.initial, required this.kinds});

  @override
  ConsumerState<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends ConsumerState<_ContactDialog> {
  final formKey = GlobalKey<FormState>();
  final personName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final notes = TextEditingController();
  String kind = 'GENERAL';
  bool primary = false;
  bool saving = false;
  String? err;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      personName.text = init['person_name'] ?? '';
      email.text = init['email'] ?? '';
      phone.text = init['phone'] ?? '';
      notes.text = init['notes'] ?? '';
      kind = (init['kind'] ?? 'GENERAL') as String;
      primary = (init['primary_contact'] ?? false) as bool;
    }
  }

  @override
  void dispose() {
    personName.dispose();
    email.dispose();
    phone.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      saving = true;
      err = null;
    });

    try {
      final orgId = ref.read(currentOrgIdProvider);
      if (orgId == null) throw 'Aucune organisation sélectionnée';
      final supa = Supabase.instance.client;

      final payload = {
        'org_id': orgId,
        'kind': kind,
        'person_name': personName.text.trim(),
        'email': email.text.trim(),
        'phone': phone.text.trim(),
        'notes': notes.text.trim(),
        'primary_contact': primary,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (widget.initial == null) {
        payload['created_at'] = DateTime.now().toUtc().toIso8601String();
        await supa.from('org_contacts').insert(payload);
      } else {
        await supa
            .from('org_contacts')
            .update(payload)
            .eq('id', widget.initial!['id'] as String);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Contact enregistré.')));
    } catch (e) {
      setState(() => err = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(
        widget.initial == null ? 'Nouveau contact' : 'Modifier le contact',
      ),
      content: SizedBox(
        width: 560,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: kind,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final k in widget.kinds)
                    DropdownMenuItem(value: k, child: Text(k)),
                ],
                onChanged: (v) => setState(() => kind = v ?? 'GENERAL'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: personName,
                decoration: const InputDecoration(labelText: 'Nom *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Contact principal'),
                value: primary,
                onChanged: (v) => setState(() => primary = v),
              ),
              if (err != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(err!, style: TextStyle(color: scheme.error)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving
              ? null
              : () => Navigator.of(context).maybePop(false),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: saving ? null : _save,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(saving ? 'Enregistrement…' : 'Enregistrer'),
        ),
      ],
    );
  }
}
