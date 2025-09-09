import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';
import 'org_state.dart';

class OrgCreatePage extends ConsumerStatefulWidget {
  const OrgCreatePage({super.key});

  @override
  ConsumerState<OrgCreatePage> createState() => _OrgCreatePageState();
}

class _OrgCreatePageState extends ConsumerState<OrgCreatePage> {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  bool creating = false;
  String? err;

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      creating = true;
      err = null;
    });
    try {
      final id = await createOrganization(nameCtrl.text.trim());
      // garantit que la liste sera rechargée au prochain watch
      ref.invalidate(orgMembershipsProvider);
      ref.read(currentOrgIdProvider.notifier).state = id;
      if (!mounted) return;
      context.go(Routes.dashboard); // ⬅️ redirige vers dashboard
    } catch (e) {
      setState(() => err = e.toString());
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer une organisation')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de l’organisation *',
                hintText: 'Ex: AG CLEANING FACILITY SERVICES S.R.L.',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            if (err != null)
              Text(
                err!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 6),
            FilledButton.icon(
              onPressed: creating ? null : _create,
              icon: creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(creating ? 'Création…' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }
}
