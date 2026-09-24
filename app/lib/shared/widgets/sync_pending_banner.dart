import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/database/cache_age.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/l10n/app_localizations.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

/// Persistent offline/pending banner under the date (Task 02). Not a snack.
class SyncPendingBanner extends ConsumerWidget {
  const SyncPendingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingWriteCountProvider);
    final stuck = ref.watch(stuckWriteProvider).valueOrNull ?? false;
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final cachedAt = ref.watch(cacheFreshnessProvider).valueOrNull;
    final age = (!online && cachedAt != null)
        ? cacheAge(cachedAt, DateTime.now())
        : null;
    return pending.when(
      data: (count) {
        if (count <= 0 && age == null) {
          return const SizedBox.shrink();
        }
        final l10n = context.l10n;
        final colors = Theme.of(context).vrijdagColors;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, VrijdagSpacing.sm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.banner,
              borderRadius: BorderRadius.circular(VrijdagRadii.control),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (count > 0)
                    Text(
                      l10n.syncPendingCount(count),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: colors.ink,
                      ),
                    ),
                  if (count > 0) const SizedBox(height: VrijdagSpacing.xxs),
                  Text(
                    stuck ? l10n.syncStuckBody : l10n.errorsOfflineBody,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      height: 1.4,
                      color: colors.inkSoft,
                    ),
                  ),
                  if (age != null) ...[
                    const SizedBox(height: VrijdagSpacing.xxs),
                    Text(
                      _ageLabel(l10n, age),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        height: 1.4,
                        color: colors.inkSoft,
                      ),
                    ),
                  ],
                  if (stuck)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => _retry(ref),
                        child: Text(l10n.syncRetry),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  String _ageLabel(AppLocalizations l10n, CacheAge age) {
    return switch (age.unit) {
      CacheAgeUnit.minutes => l10n.syncStaleMinutes(age.count),
      CacheAgeUnit.hours => l10n.syncStaleHours(age.count),
      CacheAgeUnit.days => l10n.syncStaleDays(age.count),
    };
  }

  Future<void> _retry(WidgetRef ref) async {
    final queue = ref.read(writeQueueProvider);
    final head = await queue.peekOrdered(limit: 1);
    if (head.isEmpty) {
      return;
    }
    await queue.resetAttempts(head.first.id);
    await ref.read(writeQueueReplayerProvider).replayOnce();
    ref.invalidate(pendingWriteCountProvider);
    ref.invalidate(stuckWriteProvider);
  }
}
