import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';
import 'package:vrijdag/features/auth/presentation/auth_providers.dart';

/// Utilitarian magic-link + Apple sign-in (F-002). Design polish comes later.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  static const emailRedirectTo = 'nl.vrijdag.vrijdag://login-callback/';

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  var _sending = false;
  var _sent = false;
  var _appleBusy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    final l10n = context.l10n;
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = l10n.authInvalidEmail);
      return;
    }

    if (!ref.read(supabaseReadyProvider)) {
      setState(() => _error = l10n.authSupabaseRequired);
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .sendMagicLink(
            email: email,
            emailRedirectTo: SignInScreen.emailRedirectTo,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _sending = false;
        _sent = true;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _sending = false;
        _error = l10n.authSendFailed;
      });
    }
  }

  Future<void> _submitApple() async {
    final l10n = context.l10n;
    if (!ref.read(supabaseReadyProvider)) {
      setState(() => _error = l10n.authSupabaseRequired);
      return;
    }

    setState(() {
      _appleBusy = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithApple();
      if (!mounted) {
        return;
      }
      setState(() => _appleBusy = false);
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _appleBusy = false;
        _error = l10n.authAppleFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = _sending || _appleBusy;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authSignInTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_sent) ...[
              Text(l10n.authCheckEmail),
            ] else ...[
              FilledButton(
                onPressed: busy ? null : _submitApple,
                child: Text(l10n.authSignInWithApple),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.authOrEmail,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: l10n.authEmailLabel),
                enabled: !busy,
                onSubmitted: (_) => _submitEmail(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: busy ? null : _submitEmail,
                child: Text(l10n.authSendMagicLink),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
