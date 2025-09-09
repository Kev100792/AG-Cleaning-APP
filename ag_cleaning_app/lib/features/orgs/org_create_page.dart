import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'org_state.dart';

class OrgCreatePage extends ConsumerStatefulWidget {
  const OrgCreatePage({super.key});
  @override
  ConsumerState<OrgCreatePage> createState() => _OrgCreatePageState();
}

class _OrgCreatePageState extends ConsumerState<OrgCreatePage> {
  final _formKey = GlobalKey<FormState>();

  // Identité (BE)
  final name = TextEditingController();
  final legalFormBE = ValueNotifier<String>('SRL');
  final enterpriseNumber = TextEditingController(); // BCE/KBO
  final vat = TextEditingController(); // TVA
  final naceCodes = TextEditingController(); // "81210,81220"

  // Adresse (BE) — rue & numéro séparés
  final street = TextEditingController();
  final number = TextEditingController();
  final boxCtrl = TextEditingController();
  final postal = TextEditingController();
  final city = TextEditingController();
  final province = TextEditingController();
  final country = TextEditingController(text: 'BE');

  // Contact org
  final companyEmail = TextEditingController();
  final phone = TextEditingController();
  final website = TextEditingController();

  // Région & TVA
  final timezone = TextEditingController(text: 'Europe/Brussels');
  final currency = TextEditingController(text: 'EUR');
  final language = TextEditingController(text: 'fr');
  final vatRegime = ValueNotifier<String>(
    'NORMAL',
  ); // NORMAL / EXEMPT_SMALL_ENTERPRISE / MARGIN_SCHEME / OTHER

  // Contacts dédiés
  final genName = TextEditingController();
  final genEmail = TextEditingController();
  final genPhone = TextEditingController();

  final billName = TextEditingController();
  final billEmail = TextEditingController();
  final billPhone = TextEditingController();

  bool busy = false;
  String? err;

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
    genName.dispose();
    genEmail.dispose();
    genPhone.dispose();
    billName.dispose();
    billEmail.dispose();
    billPhone.dispose();
    legalFormBE.dispose();
    vatRegime.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      busy = true;
      err = null;
    });
    try {
      final res = await Supabase.instance.client.rpc(
        'create_organization',
        params: {
          'p_name': name.text.trim(),
          'p_vat': vat.text.trim().isEmpty ? null : vat.text.trim(),
          // rétro-compat laissés à null
          'p_address': null,
          'p_legal_form': null,
          'p_company_reg_no': null,
          'p_company_email': companyEmail.text.trim().isEmpty
              ? null
              : companyEmail.text.trim(),
          'p_phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
          'p_website': website.text.trim().isEmpty ? null : website.text.trim(),
          'p_timezone': timezone.text.trim().isEmpty
              ? 'Europe/Brussels'
              : timezone.text.trim(),
          'p_currency': currency.text.trim().isEmpty
              ? 'EUR'
              : currency.text.trim(),
          'p_language': language.text.trim().isEmpty
              ? 'fr'
              : language.text.trim(),
          'p_vat_regime': vatRegime.value,
          'p_settings': <String, dynamic>{},
          // Nouveaux (BE + adresse détaillée)
          'p_legal_form_be': legalFormBE.value,
          'p_enterprise_number': enterpriseNumber.text.trim().isEmpty
              ? null
              : enterpriseNumber.text.trim(),
          'p_address_street': street.text.trim().isEmpty
              ? null
              : street.text.trim(),
          'p_address_number': number.text.trim().isEmpty
              ? null
              : number.text.trim(),
          'p_address_box': boxCtrl.text.trim().isEmpty
              ? null
              : boxCtrl.text.trim(),
          'p_postal_code': postal.text.trim().isEmpty
              ? null
              : postal.text.trim(),
          'p_city': city.text.trim().isEmpty ? null : city.text.trim(),
          'p_province': province.text.trim().isEmpty
              ? null
              : province.text.trim(),
          'p_country': country.text.trim().isEmpty ? 'BE' : country.text.trim(),
          'p_nace_codes': naceCodes.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
          // Contacts initiaux
          'p_contact_general': {
            'person_name': genName.text.trim(),
            'email': genEmail.text.trim(),
            'phone': genPhone.text.trim(),
            'primary': true,
          },
          'p_contact_billing': {
            'person_name': billName.text.trim(),
            'email': billEmail.text.trim(),
            'phone': billPhone.text.trim(),
            'primary': true,
          },
        },
      );

      final orgId = res as String;
      ref.invalidate(orgMembershipsProvider);
      ref.read(currentOrgIdProvider.notifier).state = orgId;

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Organisation créée.')));
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      setState(() => err = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const legalForms = [
      'SRL',
      'SA',
      'ASBL',
      'SC',
      'SNC',
      'SComm',
      'SPFPL',
      'Autre',
    ];
    const vatRegimeOptions = [
      'NORMAL',
      'EXEMPT_SMALL_ENTERPRISE',
      'MARGIN_SCHEME',
      'OTHER',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Créer une organisation')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text(
                    'Identité (Belgique)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 480,
                        child: TextFormField(
                          controller: name,
                          decoration: const InputDecoration(
                            labelText: 'Nom commercial *',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requis' : null,
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: DropdownButtonFormField<String>(
                          initialValue: legalFormBE.value,
                          items: [
                            for (final f in legalForms)
                              DropdownMenuItem(value: f, child: Text(f)),
                          ],
                          onChanged: (v) => legalFormBE.value = v ?? 'SRL',
                          decoration: const InputDecoration(
                            labelText: 'Forme juridique (BE)',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: TextFormField(
                          controller: enterpriseNumber,
                          decoration: const InputDecoration(
                            labelText: 'N° d’entreprise (BCE/KBO)',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: TextFormField(
                          controller: vat,
                          decoration: const InputDecoration(
                            labelText: 'N° TVA (ex. BE0xxxxxxxxx)',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: TextFormField(
                          controller: naceCodes,
                          decoration: const InputDecoration(
                            labelText: 'Codes NACE (ex: 81210,81220)',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Adresse',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 420,
                        child: TextFormField(
                          controller: street,
                          decoration: const InputDecoration(labelText: 'Rue'),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: number,
                          decoration: const InputDecoration(labelText: 'N°'),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: boxCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Boîte / Bus',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: postal,
                          decoration: const InputDecoration(
                            labelText: 'Code postal',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: TextFormField(
                          controller: city,
                          decoration: const InputDecoration(
                            labelText: 'Commune / Ville',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: TextFormField(
                          controller: province,
                          decoration: const InputDecoration(
                            labelText: 'Province / Région',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: country,
                          decoration: const InputDecoration(
                            labelText: 'Pays (ISO, ex. BE)',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Contact & site',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 340,
                        child: TextFormField(
                          controller: companyEmail,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email société',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: TextFormField(
                          controller: phone,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 340,
                        child: TextFormField(
                          controller: website,
                          decoration: const InputDecoration(
                            labelText: 'Site web',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Région & TVA',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 260,
                        child: TextFormField(
                          controller: timezone,
                          decoration: const InputDecoration(
                            labelText: 'Fuseau horaire',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: currency,
                          decoration: const InputDecoration(
                            labelText: 'Devise',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: language,
                          decoration: const InputDecoration(
                            labelText: 'Langue',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 320,
                        child: DropdownButtonFormField<String>(
                          initialValue: vatRegime.value,
                          items: [
                            for (final f in vatRegimeOptions)
                              DropdownMenuItem(value: f, child: Text(f)),
                          ],
                          onChanged: (v) => vatRegime.value = v ?? 'NORMAL',
                          decoration: const InputDecoration(
                            labelText: 'Régime TVA',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Contacts dédiés',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Général',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: 260,
                                child: TextFormField(
                                  controller: genName,
                                  decoration: const InputDecoration(
                                    labelText: 'Nom',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 260,
                                child: TextFormField(
                                  controller: genEmail,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: TextFormField(
                                  controller: genPhone,
                                  decoration: const InputDecoration(
                                    labelText: 'Téléphone',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Facturation / Comptabilité',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: 260,
                                child: TextFormField(
                                  controller: billName,
                                  decoration: const InputDecoration(
                                    labelText: 'Nom',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 260,
                                child: TextFormField(
                                  controller: billEmail,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: TextFormField(
                                  controller: billPhone,
                                  decoration: const InputDecoration(
                                    labelText: 'Téléphone',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (err != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      err!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        child: const Text('Annuler'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: busy ? null : _submit,
                        icon: const Icon(Icons.save),
                        label: Text(busy ? '...' : 'Créer l’organisation'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
