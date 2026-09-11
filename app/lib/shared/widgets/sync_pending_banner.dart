import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

/// Persistent offline/pending banner under the date (Task 02). Not a snack.
class SyncPendingBanner extends ConsumerWidget {
  const SyncPendingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingWriteCountProvider);
    return pending.when(
      data: (count) {
        if (count <= 0) {
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
                  Text(
                    l10n.syncPendingCount(count),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: VrijdagSpacing.xxs),
                  Text(
                    l10n.errorsOfflineBody,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      height: 1.4,
                      color: colors.inkSoft,
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
}
