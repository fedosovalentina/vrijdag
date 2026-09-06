import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/config/config_providers.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';
import 'package:vrijdag/features/auth/presentation/auth_providers.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

/// First-run sign-in (DT-03). Apple is a black/white control, not a moss fill.
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
      await ref.read(analyticsProvider).track(const AuthMagicLinkSent());
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
      await ref
          .read(analyticsProvider)
          .track(const AuthSignInSucceeded(method: 'apple'));
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
    final colors = Theme.of(context).vrijdagColors;
    final busy = _sending || _appleBusy;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = ref.watch(appConfigProvider);
    final showTestCrash =
        kDebugMode && !config.isProduction && config.hasSentry;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VrijdagSpacing.lg,
            VrijdagSpacing.xl,
            VrijdagSpacing.lg,
            VrijdagSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.commonAppName,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: colors.ink),
              ),
              const SizedBox(height: VrijdagSpacing.sm),
              Text(
                l10n.authTagline,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
              ),
              if (showTestCrash) ...[
                const SizedBox(height: VrijdagSpacing.sm),
                Text(
                  l10n.bootstrapSentryReady,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.warmGrey),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        ref.read(errorReporterProvider).triggerTestCrash(),
                    child: Text(l10n.bootstrapTestCrash),
                  ),
                ),
              ],
              const Spacer(),
              if (_sent) ...[
                Text(
                  l10n.authCheckEmail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.ink),
                ),
                const SizedBox(height: VrijdagSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            _sent = false;
                            _error = null;
                          }),
                    child: Text(l10n.authUseDifferentEmail),
                  ),
                ),
              ] else ...[
                FilledButton(
                  onPressed: busy ? null : _submitApple,
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                  ),
                  child: Text(l10n.authSignInWithApple),
                ),
                const SizedBox(height: VrijdagSpacing.lg),
                Text(
                  l10n.authOrEmail,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.warmGrey),
                ),
                const SizedBox(height: VrijdagSpacing.md),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: colors.ink),
                  cursorColor: colors.ink,
                  decoration: InputDecoration(
                    labelText: l10n.authEmailLabel,
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.warmGrey),
                    border: const UnderlineInputBorder(),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colors.ink),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colors.ink, width: 1.5),
                    ),
                  ),
                  enabled: !busy,
                  onSubmitted: (_) => _submitEmail(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: VrijdagSpacing.sm),
                  Text(
                    _error!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.inkSoft),
                  ),
                ],
                const SizedBox(height: VrijdagSpacing.lg),
                FilledButton(
                  onPressed: busy ? null : _submitEmail,
                  child: Text(l10n.authSendMagicLink),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
