import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/localization/app_locale_provider.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/auth/domain/auth_session.dart';
import 'package:vrijdag/features/auth/domain/profile_defaults.dart';
import 'package:vrijdag/features/auth/domain/school_holiday_region.dart';
import 'package:vrijdag/features/auth/presentation/auth_providers.dart';
import 'package:vrijdag/features/onboarding/presentation/onboarding_providers.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

/// Light onboarding after first sign-in (F-003 / Task 03). Three skippable steps.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _cityController = TextEditingController();
  var _step = 0;
  late String _language;
  String? _region;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _language = 'en';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final device = resolveProfileLanguage(Localizations.localeOf(context));
      setState(() => _language = device);
      ref.read(appLocaleProvider.notifier).state = Locale(device);
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool skippedCurrent}) async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);

    // Keep answers only from steps the user passed; skip drops the rest.
    final includeCity = _step > 1 || (_step == 1 && !skippedCurrent);
    final includeRegion = _step == 2 && !skippedCurrent;
    final trimmedCity = _cityController.text.trim();
    final city = includeCity && trimmedCity.isNotEmpty ? trimmedCity : null;
    final region = includeRegion ? _region : null;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session is AuthSignedIn) {
      try {
        final profiles = ref.read(userProfileRepositoryProvider);
        final timezone = await resolveDeviceTimezoneId();
        await profiles.ensureProfile(
          userId: session.userId,
          language: _language,
          timezone: timezone,
        );
        await profiles.updatePreferences(
          userId: session.userId,
          language: _language,
          homeCity: city,
          schoolHolidayRegion: region,
        );
        ref.invalidate(userProfileProvider);
      } on Object {
        // Preferences sync must not block reaching Day.
      }
    }

    await markOnboardingCompleted(ref);
  }

  void _selectLanguage(String code) {
    setState(() => _language = code);
    ref.read(appLocaleProvider.notifier).state = Locale(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VrijdagSpacing.lg,
            VrijdagSpacing.md,
            VrijdagSpacing.lg,
            VrijdagSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _saving
                      ? null
                      : () => _finish(skippedCurrent: true),
                  child: Text(
                    _step == 1 ? l10n.onboardingCitySkip : l10n.onboardingSkip,
                  ),
                ),
              ),
              const SizedBox(height: VrijdagSpacing.md),
              Expanded(
                child: switch (_step) {
                  0 => _LanguageStep(
                    language: _language,
                    onSelect: _selectLanguage,
                  ),
                  1 => _CityStep(controller: _cityController),
                  _ => _RegionStep(
                    region: _region,
                    onSelect: (value) => setState(() => _region = value),
                  ),
                },
              ),
              FilledButton(
                onPressed: _saving
                    ? null
                    : () {
                        if (_step < 2) {
                          setState(() => _step += 1);
                          return;
                        }
                        _finish(skippedCurrent: false);
                      },
                child: Text(l10n.onboardingContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep({required this.language, required this.onSelect});

  final String language;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).vrijdagColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.onboardingLanguageTitle,
          style: textTheme.headlineMedium?.copyWith(color: colors.ink),
        ),
        const SizedBox(height: VrijdagSpacing.sm),
        Text(
          l10n.onboardingLanguageBody,
          style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
        ),
        const SizedBox(height: VrijdagSpacing.lg),
        _ChoiceButton(
          label: l10n.languageNameNl,
          selected: language == 'nl',
          onTap: () => onSelect('nl'),
        ),
        const SizedBox(height: VrijdagSpacing.sm),
        _ChoiceButton(
          label: l10n.languageNameEn,
          selected: language == 'en',
          onTap: () => onSelect('en'),
        ),
      ],
    );
  }
}

class _CityStep extends StatelessWidget {
  const _CityStep({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).vrijdagColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.onboardingCityTitle,
          style: textTheme.headlineMedium?.copyWith(color: colors.ink),
        ),
        const SizedBox(height: VrijdagSpacing.sm),
        Text(
          l10n.onboardingCityHint,
          style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
        ),
        const SizedBox(height: VrijdagSpacing.lg),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          style: textTheme.bodyLarge?.copyWith(color: colors.ink),
          cursorColor: colors.ink,
          decoration: InputDecoration(
            labelText: l10n.settingsHomeCity,
            hintText: l10n.settingsHomeCity,
          ),
        ),
      ],
    );
  }
}

class _RegionStep extends StatelessWidget {
  const _RegionStep({required this.region, required this.onSelect});

  final String? region;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).vrijdagColors;
    final textTheme = Theme.of(context).textTheme;

    final options = <(String, String)>[
      (SchoolHolidayRegion.noord, l10n.onboardingRegionNoord),
      (SchoolHolidayRegion.centraal, l10n.onboardingRegionCentraal),
      (SchoolHolidayRegion.zuid, l10n.onboardingRegionZuid),
      (SchoolHolidayRegion.unknown, l10n.onboardingRegionUnknown),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.onboardingRegionTitle,
          style: textTheme.headlineMedium?.copyWith(color: colors.ink),
        ),
        const SizedBox(height: VrijdagSpacing.lg),
        for (final option in options) ...[
          _ChoiceButton(
            label: option.$2,
            selected: region == option.$1,
            onTap: () => onSelect(option.$1),
          ),
          const SizedBox(height: VrijdagSpacing.sm),
        ],
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    final textTheme = Theme.of(context).textTheme;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        foregroundColor: colors.ink,
        backgroundColor: selected
            ? colors.ink.withValues(alpha: 0.06)
            : Colors.transparent,
        side: BorderSide(color: selected ? colors.ink : colors.dust),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: VrijdagSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VrijdagRadii.sm + 2),
        ),
      ),
      child: Text(
        label,
        style: textTheme.bodyLarge?.copyWith(color: colors.ink),
      ),
    );
  }
}
