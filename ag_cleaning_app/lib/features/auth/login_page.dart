import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool showPwd = false;
  bool busy = false;
  String? msg;

  Future<void> _signIn() async {
    setState(() {
      busy = true;
      msg = null;
    });
    try {
      if (password.text.isEmpty) {
        // Magic link
        await Supabase.instance.client.auth.signInWithOtp(
          email: email.text,
          emailRedirectTo: null,
        );
        setState(() {
          msg = 'Vérifie ta boîte mail (magic link envoyé).';
        });
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email.text,
          password: password.text,
        );
      }
    } on AuthException catch (e) {
      setState(() {
        msg = e.message;
      });
    } finally {
      setState(() {
        busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Connexion',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: !showPwd,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe (laisser vide pour magic link)',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => showPwd = !showPwd),
                        icon: Icon(
                          showPwd ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: busy ? null : _signIn,
                      child: Text(busy ? '...' : 'Continuer'),
                    ),
                  ),
                  if (msg != null) ...[
                    const SizedBox(height: 12),
                    Text(msg!, style: TextStyle(color: scheme.tertiary)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
