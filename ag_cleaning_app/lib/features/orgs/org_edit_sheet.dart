import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'org_state.dart';

class OrgEditSheet extends ConsumerStatefulWidget {
  const OrgEditSheet({super.key});

  @override
  ConsumerState<OrgEditSheet> createState() => _OrgEditSheetState();
}

class _OrgEditSheetState extends ConsumerState<OrgEditSheet> {
  final formKey = GlobalKey<FormState>();

  // controllers
  final name = TextEditingController();
  final legalFormBE = ValueNotifier<String>('SRL');
  final enterpriseNumber = TextEditingController();
  final vat = TextEditingController();
  final naceCodes = TextEditingController();

  final street = TextEditingController();
  final number = TextEditingController();
  final boxCtrl = TextEditingController();
  final postal = TextEditingController();
  final city = TextEditingController();
  final province = TextEditingController();
  final country = TextEditingController(text: 'BE');

  final companyEmail = TextEditingController();
  final phone = TextEditingController();
  final website = TextEditingController();

  final timezone = TextEditingController(text: 'Europe/Brussels');
  final currency = TextEditingController(text: 'EUR');
  final language = TextEditingController(text: 'fr');
  final vatRegime = ValueNotifier<String>('NORMAL');

  bool loading = true;
  bool saving = false;
  String? err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    name.dispose();
    enterpriseNumber.dispose();
    vat.dispose();
    naceCodes.dispose();
    street.dispose();
    number.dispose();
    boxCtrl.dispose();
    postal.dispose();
    city.dispose();
    province.dispose();
    country.dispose();
    companyEmail.dispose();
    phone.dispose();
    website.dispose();
    timezone.dispose();
    currency.dispose();
    language.dispose();
    legalFormBE.dispose();
    vatRegime.dispose();
    super.dispose();
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
      final Map<String, dynamic> data =
          await supa
                  .from('orgs')
                  .select() // <-- pas de générique ici
                  .eq('id', orgId)
                  .single()
              as Map<String, dynamic>; // <-- cast ici

      name.text = data['name'] ?? '';
      legalFormBE.value = (data['legal_form_be'] ?? 'SRL') as String;
      enterpriseNumber.text = data['enterprise_number'] ?? '';
      vat.text = data['vat'] ?? '';
      (naceCodes.text = (data['nace_codes'] as List?)?.join(',') ?? '');

      street.text = data['address_street'] ?? '';
      number.text = data['address_number'] ?? '';
      boxCtrl.text = data['address_box'] ?? '';
      postal.text = data['postal_code'] ?? '';
      city.text = data['city'] ?? '';
      province.text = data['province'] ?? '';
      country.text = data['country'] ?? 'BE';

      companyEmail.text = data['company_email'] ?? '';
      phone.text = data['phone'] ?? '';
      website.text = data['website'] ?? '';

      timezone.text = data['timezone'] ?? 'Europe/Brussels';
      currency.text = data['default_currency'] ?? 'EUR';
      language.text = data['language'] ?? 'fr';
      vatRegime.value = (data['vat_regime'] ?? 'NORMAL') as String;
    } catch (e) {
      err = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
      await supa
          .from('orgs')
          .update({
            'name': name.text.trim(),
            'legal_form_be': legalFormBE.value,
            'enterprise_number': enterpriseNumber.text.trim(),
            'vat': vat.text.trim(),
            'nace_codes': naceCodes.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
            'address_street': street.text.trim(),
            'address_number': number.text.trim(),
            'address_box': boxCtrl.text.trim(),
            'postal_code': postal.text.trim(),
            'city': city.text.trim(),
            'province': province.text.trim(),
            'country': country.text.trim().isEmpty ? 'BE' : country.text.trim(),
            'company_email': companyEmail.text.trim(),
            'phone': phone.text.trim(),
            'website': website.text.trim(),
            'timezone': timezone.text.trim().isEmpty
                ? 'Europe/Brussels'
                : timezone.text.trim(),
            'default_currency': currency.text.trim().isEmpty
                ? 'EUR'
                : currency.text.trim(),
            'language': language.text.trim().isEmpty
                ? 'fr'
                : language.text.trim(),
            'vat_regime': vatRegime.value,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', orgId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organisation enregistrée.')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      setState(() => err = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Form(
      key: formKey,
      child: Stack(
        children: [
          // Contenu scrollable
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section(
                    title: 'Identité',
                    children: [
                      _col(
                        480,
                        TextFormField(
                          controller: name,
                          decoration: const InputDecoration(
                            labelText: 'Nom commercial *',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requis' : null,
                        ),
                      ),
                      _col(
                        220,
                        _Dropdown<String>(
                          label: 'Forme juridique (BE)',
                          initial: legalFormBE.value,
                          items: const [
                            'SRL',
                            'SA',
                            'ASBL',
                            'SC',
                            'SNC',
                            'SComm',
                            'SPFPL',
                            'Autre',
                          ],
                          onChanged: (v) => legalFormBE.value = v ?? 'SRL',
                        ),
                      ),
                      _col(
                        220,
                        TextFormField(
                          controller: enterpriseNumber,
                          decoration: const InputDecoration(
                            labelText: 'N° entreprise (BCE/KBO)',
                          ),
                        ),
                      ),
                      _col(
                        220,
                        TextFormField(
                          controller: vat,
                          decoration: const InputDecoration(
                            labelText: 'N° TVA (ex. BE0xxxxxxxxx)',
                          ),
                        ),
                      ),
                      _col(
                        280,
                        TextFormField(
                          controller: naceCodes,
                          decoration: const InputDecoration(
                            labelText: 'Codes NACE (ex: 81210,81220)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Adresse',
                    children: [
                      _col(
                        420,
                        TextFormField(
                          controller: street,
                          decoration: const InputDecoration(labelText: 'Rue'),
                        ),
                      ),
                      _col(
                        120,
                        TextFormField(
                          controller: number,
                          decoration: const InputDecoration(labelText: 'N°'),
                        ),
                      ),
                      _col(
                        120,
                        TextFormField(
                          controller: boxCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Boîte / Bus',
                          ),
                        ),
                      ),
                      _col(
                        160,
                        TextFormField(
                          controller: postal,
                          decoration: const InputDecoration(
                            labelText: 'Code postal',
                          ),
                        ),
                      ),
                      _col(
                        240,
                        TextFormField(
                          controller: city,
                          decoration: const InputDecoration(
                            labelText: 'Commune / Ville',
                          ),
                        ),
                      ),
                      _col(
                        220,
                        TextFormField(
                          controller: province,
                          decoration: const InputDecoration(
                            labelText: 'Province / Région',
                          ),
                        ),
                      ),
                      _col(
                        100,
                        TextFormField(
                          controller: country,
                          decoration: const InputDecoration(
                            labelText: 'Pays (ISO, ex. BE)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Contact',
                    children: [
                      _col(
                        320,
                        TextFormField(
                          controller: companyEmail,
                          decoration: const InputDecoration(
                            labelText: 'Email société',
                          ),
                        ),
                      ),
                      _col(
                        220,
                        TextFormField(
                          controller: phone,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone',
                          ),
                        ),
                      ),
                      _col(
                        320,
                        TextFormField(
                          controller: website,
                          decoration: const InputDecoration(
                            labelText: 'Site web',
                          ),
                        ),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Régional & TVA',
                    children: [
                      _col(
                        240,
                        TextFormField(
                          controller: timezone,
                          decoration: const InputDecoration(
                            labelText: 'Fuseau horaire',
                          ),
                        ),
                      ),
                      _col(
                        140,
                        TextFormField(
                          controller: currency,
                          decoration: const InputDecoration(
                            labelText: 'Devise',
                          ),
                        ),
                      ),
                      _col(
                        140,
                        TextFormField(
                          controller: language,
                          decoration: const InputDecoration(
                            labelText: 'Langue',
                          ),
                        ),
                      ),
                      _col(
                        280,
                        _Dropdown<String>(
                          label: 'Régime TVA',
                          initial: vatRegime.value,
                          items: const [
                            'NORMAL',
                            'EXEMPT_SMALL_ENTERPRISE',
                            'MARGIN_SCHEME',
                            'OTHER',
                          ],
                          onChanged: (v) => vatRegime.value = v ?? 'NORMAL',
                        ),
                      ),
                    ],
                  ),
                  if (err != null) ...[
                    const SizedBox(height: 12),
                    Text(err!, style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          // Barre d’actions collée en bas
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
                    onPressed: saving
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Annuler'),
                  ),
                  const Spacer(),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers mise en page
  Widget _col(double width, Widget child) {
    return SizedBox(width: width, child: child);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(spacing: 16, runSpacing: 16, children: children),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T? initial;
  final List<T> items;
  final void Function(T?)? onChanged;
  const _Dropdown({
    required this.label,
    required this.initial,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      initialValue: initial, // <-- au lieu de value:
      decoration: InputDecoration(labelText: label),
      items: [
        for (final it in items)
          DropdownMenuItem<T>(value: it, child: Text('$it')),
      ],
      onChanged: onChanged,
    );
  }
}
