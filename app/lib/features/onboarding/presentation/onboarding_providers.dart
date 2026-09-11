import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const onboardingCompletedPrefsKey = 'onboarding_completed';

/// Whether light onboarding (F-003) has been finished or skipped on this device.
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(onboardingCompletedPrefsKey) ?? false;
});

Future<void> markOnboardingCompleted(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(onboardingCompletedPrefsKey, true);
  ref.invalidate(onboardingCompletedProvider);
}
