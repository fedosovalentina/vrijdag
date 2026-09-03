import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/birthdays/presentation/birthday_editor_screen.dart';
import 'package:vrijdag/features/birthdays/presentation/birthday_providers.dart';
import 'package:vrijdag/l10n/app_localizations.dart';
import 'package:vrijdag/shared/widgets/event_row.dart';
import 'package:vrijdag/shared/widgets/quiet_state.dart';

class BirthdaysPanel extends ConsumerWidget {
  const BirthdaysPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final birthdays = ref.watch(birthdaysListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.birthdaySectionTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const BirthdayEditorScreen(),
                  ),
                );
                ref.invalidate(birthdaysListProvider);
              },
              child: Text(l10n.birthdayNew),
            ),
          ],
        ),
        birthdays.when(
          data: (items) {
            if (items.isEmpty) {
              return QuietState(message: l10n.birthdayEmpty);
            }
            final now = DateTime.now();
            return Column(
              children: [
                for (final birthday in items)
                  Row(
                    children: [
                      Expanded(
                        child: EventRow(
                          title: birthday.name,
                          subtitle: _subtitle(l10n, birthday, now),
                          kind: EventMarkerKind.birthday,
                          onTap: () async {
                            await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    BirthdayEditorScreen(existing: birthday),
                              ),
                            );
                            ref.invalidate(birthdaysListProvider);
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => _delete(context, ref, birthday),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n.commonDelete,
                      ),
                    ],
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Text(l10n.birthdayLoadFailed),
        ),
      ],
    );
  }

  String _subtitle(AppLocalizations l10n, Birthday birthday, DateTime now) {
    final date =
        '${birthday.day.toString().padLeft(2, '0')}.${birthday.month.toString().padLeft(2, '0')}';
    final age = birthday.ageOn(now);
    if (age == null) {
      return date;
    }
    return '$date · ${l10n.birthdayAge(age)}';
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Birthday birthday,
  ) async {
    final l10n = context.l10n;
    await ref.read(birthdaysRepositoryProvider).softDelete(birthday.id);
    await ref.read(analyticsProvider).track(const BirthdayDeleted());
    ref.invalidate(birthdaysListProvider);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.birthdayDeleted)));
  }
}
