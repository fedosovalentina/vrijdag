import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/auth/domain/profile_defaults.dart';
import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';
import 'package:vrijdag/l10n/app_localizations.dart';

/// Create or edit a personal event (utilitarian F-004 UI).
class EventEditorScreen extends ConsumerStatefulWidget {
  const EventEditorScreen({super.key, this.existing, this.initialStartLocal});

  final PersonalEvent? existing;

  /// Prefill for Nieuw from an empty hour on Day (DEC-025).
  final DateTime? initialStartLocal;

  @override
  ConsumerState<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends ConsumerState<EventEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  late DateTime _startLocal;
  late DateTime _endLocal;
  late bool _allDay;
  RecurrenceFrequency? _frequency;
  DateTime? _recurrenceUntil;
  var _saving = false;
  var _viewing = false;
  var _multiDay = false;
  var _detailsOpen = false;
  String? _error;
  String? _rangeHint;

  bool get _isEdit => widget.existing != null;

  bool get _hasDetails =>
      _location.text.trim().isNotEmpty ||
      _notes.text.trim().isNotEmpty ||
      _frequency != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _location = TextEditingController(text: existing?.location ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _frequency = existing?.recurrenceRule?.frequency;
    final until = existing?.recurrenceUntil;
    _recurrenceUntil = until == null
        ? null
        : DateTime(until.year, until.month, until.day);

    if (existing?.timed != null) {
      _allDay = false;
      _startLocal = existing!.timed!.startsAt.toLocal();
      _endLocal = existing.timed!.endsAt.toLocal();
    } else if (existing?.allDay != null) {
      _allDay = true;
      final span = existing!.allDay!;
      _startLocal = DateTime(
        span.startDate.year,
        span.startDate.month,
        span.startDate.day,
      );
      _endLocal = DateTime(
        span.endDate.year,
        span.endDate.month,
        span.endDate.day,
      );
    } else {
      _allDay = false;
      final seed = widget.initialStartLocal;
      _startLocal = seed == null
          ? _roundToNextQuarter(DateTime.now())
          : DateTime(seed.year, seed.month, seed.day, seed.hour);
      _endLocal = _startLocal.add(defaultTimedEventDuration);
    }
    _viewing = existing != null;
    _multiDay = !_sameDay(_startLocal, _endLocal);
    _detailsOpen = _hasDetails;
  }

  void _restoreSaved() {
    final existing = widget.existing;
    if (existing == null) {
      return;
    }
    _title.text = existing.title;
    _location.text = existing.location ?? '';
    _notes.text = existing.notes ?? '';
    _frequency = existing.recurrenceRule?.frequency;
    final until = existing.recurrenceUntil;
    _recurrenceUntil = until == null
        ? null
        : DateTime(until.year, until.month, until.day);
    if (existing.timed != null) {
      _allDay = false;
      _startLocal = existing.timed!.startsAt.toLocal();
      _endLocal = existing.timed!.endsAt.toLocal();
    } else if (existing.allDay != null) {
      _allDay = true;
      final span = existing.allDay!;
      _startLocal = DateTime(
        span.startDate.year,
        span.startDate.month,
        span.startDate.day,
      );
      _endLocal = DateTime(
        span.endDate.year,
        span.endDate.month,
        span.endDate.day,
      );
    }
    _multiDay = !_sameDay(_startLocal, _endLocal);
    _detailsOpen = _hasDetails;
    _error = null;
    _rangeHint = null;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _rangeExceedsCap() {
    final start = DateTime(
      _startLocal.year,
      _startLocal.month,
      _startLocal.day,
    );
    final end = DateTime(_endLocal.year, _endLocal.month, _endLocal.day);
    return end.difference(start).inDays > 30;
  }

  DateTime _roundToNextQuarter(DateTime value) {
    final minutes = ((value.minute + 14) ~/ 15) * 15;
    var result = DateTime(value.year, value.month, value.day, value.hour, 0);
    result = result.add(Duration(minutes: minutes));
    if (!result.isAfter(value)) {
      result = result.add(const Duration(minutes: 15));
    }
    return result;
  }

  static String _weekdayCode(DateTime value) {
    return const ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'][value.weekday - 1];
  }

  RecurrenceRule? _buildRecurrenceRule() {
    final frequency = _frequency;
    if (frequency == null) {
      return null;
    }
    return RecurrenceRule(
      frequency: frequency,
      byDay: frequency == RecurrenceFrequency.weekly
          ? [_weekdayCode(_startLocal)]
          : const [],
    );
  }

  DateTime? get _effectiveRecurrenceUntil =>
      _frequency == null ? null : _recurrenceUntil;

  String _frequencyLabel(AppLocalizations l10n) {
    return switch (_frequency) {
      null => l10n.calendarRecurrenceDoesNotRepeat,
      RecurrenceFrequency.daily => l10n.calendarRecurrenceDaily,
      RecurrenceFrequency.weekly => l10n.calendarRecurrenceWeekly,
      RecurrenceFrequency.monthly => l10n.calendarRecurrenceMonthly,
      RecurrenceFrequency.yearly => l10n.calendarRecurrenceYearly,
    };
  }

  Future<void> _pickFrequencyChoice() async {
    final l10n = context.l10n;
    final result = await showModalBottomSheet<_FrequencyChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.calendarRecurrenceDoesNotRepeat),
                onTap: () =>
                    Navigator.of(context).pop(const _FrequencyChoice(null)),
              ),
              ListTile(
                title: Text(l10n.calendarRecurrenceDaily),
                onTap: () => Navigator.of(
                  context,
                ).pop(const _FrequencyChoice(RecurrenceFrequency.daily)),
              ),
              ListTile(
                title: Text(l10n.calendarRecurrenceWeekly),
                onTap: () => Navigator.of(
                  context,
                ).pop(const _FrequencyChoice(RecurrenceFrequency.weekly)),
              ),
              ListTile(
                title: Text(l10n.calendarRecurrenceMonthly),
                onTap: () => Navigator.of(
                  context,
                ).pop(const _FrequencyChoice(RecurrenceFrequency.monthly)),
              ),
              ListTile(
                title: Text(l10n.calendarRecurrenceYearly),
                onTap: () => Navigator.of(
                  context,
                ).pop(const _FrequencyChoice(RecurrenceFrequency.yearly)),
              ),
            ],
          ),
        );
      },
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _frequency = result.frequency;
      if (_frequency == null) {
        _recurrenceUntil = null;
      }
    });
  }

  Future<void> _pickRecurrenceEnds() async {
    final l10n = context.l10n;
    final result = await showModalBottomSheet<_EndsChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.calendarRecurrenceEndsNever),
                onTap: () =>
                    Navigator.of(context).pop(const _EndsChoice.never()),
              ),
              ListTile(
                title: Text(l10n.calendarRecurrenceEndsOnDate),
                onTap: () =>
                    Navigator.of(context).pop(const _EndsChoice.onDate()),
              ),
            ],
          ),
        );
      },
    );
    if (result == null || !mounted) {
      return;
    }
    if (result.never) {
      setState(() => _recurrenceUntil = null);
      return;
    }
    final initial = _recurrenceUntil ?? _startLocal;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(_startLocal.year, _startLocal.month, _startLocal.day),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return;
    }
    setState(() {
      _recurrenceUntil = DateTime(date.year, date.month, date.day);
    });
  }

  Future<void> _pickStart() async {
    if (_allDay) {
      final date = await showDatePicker(
        context: context,
        initialDate: _startLocal,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date == null) {
        return;
      }
      setState(() {
        final duration = _endLocal.difference(
          DateTime(_startLocal.year, _startLocal.month, _startLocal.day),
        );
        _startLocal = DateTime(date.year, date.month, date.day);
        _endLocal = _startLocal.add(
          duration.isNegative ? Duration.zero : duration,
        );
        if (_endLocal.isBefore(_startLocal)) {
          _endLocal = _startLocal;
        }
      });
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: _startLocal,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startLocal),
    );
    if (time == null) {
      return;
    }
    setState(() {
      final duration = _endLocal.difference(_startLocal);
      _startLocal = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _endLocal = _startLocal.add(
        duration.isNegative ? defaultTimedEventDuration : duration,
      );
    });
  }

  Future<void> _pickEnd() async {
    if (_allDay) {
      final date = await showDatePicker(
        context: context,
        initialDate: _endLocal,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date == null) {
        return;
      }
      setState(() {
        _endLocal = DateTime(date.year, date.month, date.day);
      });
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: _endLocal,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endLocal),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _endLocal = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final title = _title.text.trim().isEmpty
        ? l10n.eventUntitled
        : _title.text.trim();

    if (_rangeExceedsCap()) {
      setState(() => _rangeHint = l10n.eventRangeTooLong);
      return;
    }

    if (_allDay) {
      final start = DateTime(
        _startLocal.year,
        _startLocal.month,
        _startLocal.day,
      );
      final end = DateTime(_endLocal.year, _endLocal.month, _endLocal.day);
      if (end.isBefore(start)) {
        setState(() => _error = l10n.calendarInvalidRange);
        return;
      }
    } else if (_endLocal.isBefore(_startLocal)) {
      setState(() => _error = l10n.calendarInvalidRange);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(personalEventsRepositoryProvider);
      final analytics = ref.read(analyticsProvider);
      final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
      final location = _location.text.trim().isEmpty
          ? null
          : _location.text.trim();
      final timezone = await resolveDeviceTimezoneId();
      final recurrenceRule = _buildRecurrenceRule();
      final recurrenceUntil = _effectiveRecurrenceUntil;

      if (_isEdit) {
        // V1: editing a recurring master updates the whole series.
        final existing = widget.existing!;
        final updated = PersonalEvent(
          id: existing.id,
          userId: existing.userId,
          title: title,
          notes: notes,
          location: location,
          timed: _allDay
              ? null
              : TimedEventSpan(
                  startsAt: _startLocal.toUtc(),
                  endsAt: _endLocal.toUtc(),
                  timezone: timezone,
                ),
          allDay: _allDay
              ? AllDayEventSpan(
                  startDate: DateTime(
                    _startLocal.year,
                    _startLocal.month,
                    _startLocal.day,
                  ),
                  endDate: DateTime(
                    _endLocal.year,
                    _endLocal.month,
                    _endLocal.day,
                  ),
                )
              : null,
          recurrenceRule: recurrenceRule,
          recurrenceUntil: recurrenceUntil,
          source: existing.source,
          sourceOfTruth: existing.sourceOfTruth,
          deletedAt: existing.deletedAt,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now().toUtc(),
        );
        await repo.update(updated);
        await analytics.track(EventEdited(source: existing.source.name));
      } else if (_allDay) {
        await repo.createAllDay(
          title: title,
          startDate: DateTime(
            _startLocal.year,
            _startLocal.month,
            _startLocal.day,
          ),
          endDate: DateTime(_endLocal.year, _endLocal.month, _endLocal.day),
          timezone: timezone,
          notes: notes,
          location: location,
          recurrenceRule: recurrenceRule,
          recurrenceUntil: recurrenceUntil,
        );
        await analytics.track(
          EventCreated(
            source: 'vrijdag',
            isAllDay: true,
            hasLocation: location != null,
          ),
        );
      } else {
        await repo.createTimed(
          NewTimedEventDraft(
            title: title,
            startsAt: _startLocal.toUtc(),
            timezone: timezone,
            duration: _endLocal.difference(_startLocal),
            notes: notes,
            location: location,
            recurrenceRule: recurrenceRule,
            recurrenceUntil: recurrenceUntil,
          ),
        );
        await analytics.track(
          EventCreated(
            source: 'vrijdag',
            isAllDay: false,
            hasLocation: location != null,
          ),
        );
      }

      if (!mounted) {
        return;
      }
      ref.invalidate(todaysEventsProvider);
      ref.invalidate(dayEventsProvider);
      ref.invalidate(visibleEventsProvider);
      Navigator.of(context).pop(true);
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = l10n.calendarSaveFailed;
      });
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) {
      return;
    }
    final l10n = context.l10n;

    if (existing.isRecurring) {
      // V1: series-only — only "all events" is offered for delete.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: Text(l10n.calendarRecurrenceScopeTitle),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.calendarRecurrenceAllEvents),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !mounted) {
        return;
      }
      await _performSoftDelete(existing, showUndo: false);
      return;
    }

    await _performSoftDelete(existing, showUndo: true);
  }

  Future<void> _performSoftDelete(
    PersonalEvent existing, {
    required bool showUndo,
  }) async {
    final l10n = context.l10n;
    final repo = ref.read(personalEventsRepositoryProvider);
    final analytics = ref.read(analyticsProvider);
    final container = ProviderScope.containerOf(context);

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await repo.softDelete(existing.id);
      await analytics.track(EventDeleted(source: existing.source.name));
      if (!mounted) {
        return;
      }
      ref.invalidate(todaysEventsProvider);
      ref.invalidate(dayEventsProvider);
      ref.invalidate(visibleEventsProvider);
      ref.invalidate(pendingWriteCountProvider);

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      if (!showUndo) {
        return;
      }
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.calendarDeleted),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: l10n.calendarUndo,
            onPressed: () async {
              await repo.undoSoftDelete(existing.id);
              await analytics.track(const EventDeleteUndone());
              container.invalidate(todaysEventsProvider);
              container.invalidate(dayEventsProvider);
              container.invalidate(visibleEventsProvider);
              container.invalidate(pendingWriteCountProvider);
            },
          ),
        ),
      );
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = l10n.calendarSaveFailed;
      });
    }
  }

  String _formatDate(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year}';
  }

  String _formatDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    if (_allDay) {
      return _formatDate(value);
    }
    return '${_formatDate(value)} ${two(value.hour)}:${two(value.minute)}';
  }

  void _cancel() {
    if (!_isEdit) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      _restoreSaved();
      _viewing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showDetails = _viewing ? _hasDetails : _detailsOpen;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _viewing
              ? (_title.text.trim().isEmpty
                    ? l10n.eventUntitled
                    : _title.text.trim())
              : (_isEdit ? l10n.calendarEditEvent : l10n.calendarNewEvent),
        ),
        actions: [
          if (_viewing)
            TextButton(
              onPressed: () => setState(() => _viewing = false),
              child: Text(l10n.eventEdit),
            )
          else
            TextButton(
              onPressed: _saving ? null : _cancel,
              child: Text(l10n.eventCancel),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_viewing)
            Text(
              _title.text.trim().isEmpty
                  ? l10n.eventUntitled
                  : _title.text.trim(),
              style: Theme.of(context).textTheme.titleLarge,
            )
          else
            TextField(
              controller: _title,
              autofocus: !_isEdit,
              decoration: InputDecoration(labelText: l10n.calendarTitleLabel),
              textCapitalization: TextCapitalization.sentences,
              enabled: !_saving,
            ),
          const SizedBox(height: 8),
          if (_viewing)
            Text(
              _allDay
                  ? (_multiDay
                        ? '${_formatDate(_startLocal)} – ${_formatDate(_endLocal)}'
                        : l10n.calendarAllDay)
                  : '${_formatDateTime(_startLocal)} – ${_formatDateTime(_endLocal)}',
            )
          else
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.calendarAllDay),
              value: _allDay,
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _allDay = value;
                        if (value) {
                          _startLocal = DateTime(
                            _startLocal.year,
                            _startLocal.month,
                            _startLocal.day,
                          );
                          _endLocal = DateTime(
                            _endLocal.year,
                            _endLocal.month,
                            _endLocal.day,
                          );
                          if (_endLocal.isBefore(_startLocal)) {
                            _endLocal = _startLocal;
                          }
                        } else {
                          _startLocal = _roundToNextQuarter(DateTime.now());
                          _endLocal = _startLocal.add(
                            defaultTimedEventDuration,
                          );
                        }
                      });
                    },
            ),
          if (!_viewing)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.calendarStartsLabel),
              subtitle: Text(_formatDateTime(_startLocal)),
              onTap: _saving ? null : _pickStart,
            ),
          if (!_viewing && !_multiDay)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() => _multiDay = true),
                child: Text(l10n.eventMakeMultiDay),
              ),
            ),
          if (!_viewing && _multiDay)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.calendarEndsLabel),
              subtitle: Text(_formatDateTime(_endLocal)),
              onTap: _saving ? null : _pickEnd,
            ),
          if (_viewing && _multiDay) Text(_formatDateTime(_endLocal)),
          if (_rangeHint != null)
            Text(
              _rangeHint!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (!_viewing && !_detailsOpen)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _detailsOpen = true),
                child: Text(l10n.eventMoreDetails),
              ),
            ),
          if (showDetails) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.calendarRecurrenceLabel),
              subtitle: Text(_frequencyLabel(l10n)),
              onTap: _viewing || _saving ? null : _pickFrequencyChoice,
            ),
            if (_frequency != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _recurrenceUntil == null
                      ? l10n.calendarRecurrenceEndsNever
                      : l10n.calendarRecurrenceEndsOnDate,
                ),
                subtitle: _recurrenceUntil == null
                    ? null
                    : Text(_formatDate(_recurrenceUntil!)),
                onTap: _viewing || _saving ? null : _pickRecurrenceEnds,
              ),
            if (_viewing && _location.text.trim().isNotEmpty)
              Text(_location.text.trim())
            else if (!_viewing)
              TextField(
                controller: _location,
                decoration: InputDecoration(
                  labelText: l10n.calendarLocationLabel,
                ),
                enabled: !_saving,
              ),
            const SizedBox(height: 16),
            if (_viewing && _notes.text.trim().isNotEmpty)
              Text(_notes.text.trim())
            else if (!_viewing)
              TextField(
                controller: _notes,
                decoration: InputDecoration(labelText: l10n.calendarNotesLabel),
                maxLines: 3,
                enabled: !_saving,
              ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          if (!_viewing)
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.commonSave),
            ),
          if (_isEdit && !_viewing) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _saving ? null : _delete,
              child: Text(l10n.commonDelete),
            ),
          ],
        ],
      ),
    );
  }
}

class _FrequencyChoice {
  const _FrequencyChoice(this.frequency);

  final RecurrenceFrequency? frequency;
}

class _EndsChoice {
  const _EndsChoice.never() : never = true;
  const _EndsChoice.onDate() : never = false;

  final bool never;
}
