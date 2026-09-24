import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/auth/domain/auth_session.dart';
import 'package:vrijdag/features/auth/presentation/auth_providers.dart';
import 'package:vrijdag/features/calendar/domain/event_category.dart';
import 'package:vrijdag/features/calendar/domain/event_search.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';
import 'package:vrijdag/shared/formatters/spoken_date.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';

/// Search titles and notes in the local cache. The query never leaves the device.
class EventSearchScreen extends ConsumerStatefulWidget {
  const EventSearchScreen({super.key, required this.onOpenEvent});

  final ValueChanged<PersonalEvent> onOpenEvent;

  @override
  ConsumerState<EventSearchScreen> createState() => _EventSearchScreenState();
}

class _EventSearchScreenState extends ConsumerState<EventSearchScreen> {
  final _query = TextEditingController();
  var _tracked = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _track(int count) async {
    if (_tracked || _query.text.trim().isEmpty) {
      return;
    }
    _tracked = true;
    await ref
        .read(analyticsProvider)
        .track(SearchUsed(resultBucket: _bucket(count)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final colors = Theme.of(context).vrijdagColors;
    final session = ref.watch(authSessionProvider).valueOrNull;
    final corpus = session is AuthSignedIn
        ? ref.watch(_searchCorpusProvider(session.userId))
        : const AsyncData<List<PersonalEvent>>([]);
    final categories =
        ref.watch(eventCategoriesProvider).valueOrNull ??
        const <EventCategory>[];
    final results = corpus.maybeWhen(
      data: (events) => searchPersonalEvents(
        masters: events,
        query: _query.text,
        now: DateTime.now(),
      ),
      orElse: () => const <PersonalEvent>[],
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchOpen)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _query,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.searchHint),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _track(results.length),
            ),
          ),
          if (_query.text.trim().isNotEmpty && results.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.searchEmpty,
                  style: TextStyle(color: colors.inkSoft),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              children: [
                for (final event in results)
                  ListTile(
                    leading: _mark(colors, categories, event.categoryId),
                    title: Text(
                      event.title,
                      style: TextStyle(color: colors.ink),
                    ),
                    subtitle: Text(
                      _when(event, locale, l10n.dayTagAllDay),
                      style: TextStyle(color: colors.inkSoft),
                    ),
                    onTap: () {
                      _track(results.length);
                      widget.onOpenEvent(event);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget? _mark(
    VrijdagColorTokens colors,
    List<EventCategory> categories,
    String? id,
  ) {
    if (id == null) {
      return null;
    }
    for (final category in categories) {
      if (category.id == id) {
        final color = switch (category.colorIndex % 4) {
          0 => colors.ink,
          1 => colors.moss,
          2 => colors.rust,
          _ => colors.gold,
        };
        return Container(width: 4, height: 24, color: color);
      }
    }
    return null;
  }

  static String _when(PersonalEvent event, Locale locale, String allDay) {
    if (event.isAllDay) {
      return '${SpokenDate.dayMonth(event.allDay!.startDate, locale)} · $allDay';
    }
    final start = event.timed!.startsAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${SpokenDate.dayMonth(start, locale)} · ${two(start.hour)}:${two(start.minute)}';
  }

  static String _bucket(int count) {
    if (count <= 0) {
      return '0';
    }
    if (count <= 2) {
      return '1-2';
    }
    if (count <= 5) {
      return '3-5';
    }
    return '6+';
  }
}

final _searchCorpusProvider = FutureProvider.autoDispose
    .family<List<PersonalEvent>, String>((ref, userId) {
      return ref.watch(personalEventsCacheProvider).listForUser(userId);
    });
