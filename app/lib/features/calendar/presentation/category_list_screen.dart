import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/calendar/domain/event_category.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/widgets/quiet_state.dart';

/// Labels the person created. An event without one simply has none.
class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = Theme.of(context).vrijdagColors;
    final categories = ref.watch(eventCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoryTitle),
        actions: [
          TextButton(
            onPressed: () => _add(context, ref),
            child: Text(l10n.categoryAdd),
          ),
        ],
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => QuietState(message: l10n.calendarLoadFailed),
        data: (items) {
          if (items.isEmpty) {
            return QuietState(message: l10n.categoryEmpty);
          }
          return ListView(
            children: [
              for (final item in items)
                ListTile(
                  leading: _Swatch(category: item),
                  title: Text(item.name, style: TextStyle(color: colors.ink)),
                  onTap: () => _rename(context, ref, item),
                  trailing: TextButton(
                    onPressed: () => ref
                        .read(eventCategoriesProvider.notifier)
                        .remove(item.id),
                    child: Text(l10n.categoryDelete),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await _askName(context, l10n.categoryAdd);
    if (name == null || !context.mounted) {
      return;
    }
    final added = await ref.read(eventCategoriesProvider.notifier).add(name);
    if (!added && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(l10n.categoryFull),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.eventCancel),
            ),
          ],
        ),
      );
    } else if (added) {
      final count = ref.read(eventCategoriesProvider).valueOrNull?.length ?? 0;
      await ref
          .read(analyticsProvider)
          .track(CategorySaved(countBucket: _bucket(count)));
    }
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    EventCategory item,
  ) async {
    final name = await _askName(context, item.name, initial: item.name);
    if (name == null) {
      return;
    }
    await ref.read(eventCategoriesProvider.notifier).rename(item.id, name);
  }

  Future<String?> _askName(
    BuildContext context,
    String title, {
    String? initial,
  }) {
    final controller = TextEditingController(text: initial ?? '');
    final l10n = context.l10n;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.categoryName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.eventCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(l10n.commonSave),
            ),
          ],
        );
      },
    );
  }

  static String _bucket(int count) {
    if (count <= 2) {
      return '1-2';
    }
    if (count <= 5) {
      return '3-5';
    }
    return '6-8';
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.category});

  final EventCategory category;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    final color = switch (category.colorIndex % 4) {
      0 => colors.ink,
      1 => colors.moss,
      2 => colors.rust,
      _ => colors.gold,
    };
    return Container(width: 14, height: 14, color: color);
  }
}
