import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/auth/domain/profile_defaults.dart';
import 'package:vrijdag/features/calendar/data/local_reminder_notifications.dart';
import 'package:vrijdag/features/calendar/domain/event_share.dart';
import 'package:vrijdag/features/calendar/domain/reminder_schedule.dart';
import 'package:vrijdag/shared/widgets/permission_explainer.dart';
import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_scope.dart';
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
  String? _categoryId;
  var _reminders = <int>[];
  var _guests = <String>[];
  var _notificationsOff = false;
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
      _frequency != null ||
      _reminders.isNotEmpty ||
      _guests.isNotEmpty ||
      _categoryId != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _location = TextEditingController(text: existing?.location ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    final seriesRule = existing?.seriesMaster ?? existing;
    _frequency = seriesRule?.recurrenceRule?.frequency;
    _categoryId = existing?.categoryId;
    _reminders = [...?existing?.reminderMinutes];
    _guests = [...?existing?.guests];
    _loadDefaultReminder();
    final until = seriesRule?.recurrenceUntil;
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
    final seriesRule = existing.seriesMaster ?? existing;
    _frequency = seriesRule.recurrenceRule?.frequency;
    _categoryId = existing.categoryId;
    _reminders = [...existing.reminderMinutes];
    _guests = [...existing.guests];
    final until = seriesRule.recurrenceUntil;
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
      final opened = widget.existing;
      final series =
          opened?.seriesMaster ??
          (opened != null && opened.isRecurring ? opened : null);
      var singleOccurrence = false;

      if (series != null && series.isRecurring) {
        final scope = await _askScope();
        if (scope == null || !mounted) {
          setState(() => _saving = false);
          return;
        }
        singleOccurrence = scope == RecurrenceScope.thisEvent;
        final occurrence =
            widget.existing!.timed?.startsAt.toLocal() ??
            widget.existing!.allDay!.startDate;
        final plan = planRecurrenceEdit(
          scope: scope,
          occurrence: occurrence,
          existingExdates: series.recurrenceExdates,
          deleting: false,
        );
        final masterTimed = plan.applyToSeries
            ? (_allDay
                  ? null
                  : TimedEventSpan(
                      startsAt: _startLocal.toUtc(),
                      endsAt: _endLocal.toUtc(),
                      timezone: timezone,
                    ))
            : series.timed;
        final masterAllDay = plan.applyToSeries
            ? (_allDay
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
                  : null)
            : series.allDay;
        final writtenSeries = PersonalEvent(
          id: series.id,
          userId: series.userId,
          title: plan.applyToSeries ? title : series.title,
          notes: plan.applyToSeries ? notes : series.notes,
          location: plan.applyToSeries ? location : series.location,
          timed: masterTimed,
          allDay: masterAllDay,
          recurrenceRule: plan.applyToSeries
              ? recurrenceRule
              : series.recurrenceRule,
          recurrenceUntil: plan.replaceUntil
              ? plan.seriesUntil
              : (plan.applyToSeries ? recurrenceUntil : series.recurrenceUntil),
          recurrenceExdates: plan.exdates,
          categoryId: plan.applyToSeries ? _categoryId : series.categoryId,
          reminderMinutes: plan.applyToSeries
              ? _reminders
              : series.reminderMinutes,
          guests: plan.applyToSeries ? _guests : series.guests,
          source: series.source,
          sourceOfTruth: series.sourceOfTruth,
          createdAt: series.createdAt,
          updatedAt: DateTime.now().toUtc(),
        );
        await repo.update(writtenSeries);
        await _remember(writtenSeries);
        if (!plan.detachOccurrence) {
          await analytics.track(EventEdited(source: series.source.name));
          await _trackDetails();
          if (!mounted) {
            return;
          }
          ref.invalidate(todaysEventsProvider);
          ref.invalidate(dayEventsProvider);
          ref.invalidate(visibleEventsProvider);
          Navigator.of(context).pop(true);
          return;
        }
      }

      final writeRule = singleOccurrence ? null : recurrenceRule;
      final writeUntil = singleOccurrence ? null : recurrenceUntil;

      if (_isEdit && series == null) {
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
          recurrenceRule: writeRule,
          recurrenceUntil: writeUntil,
          categoryId: _categoryId,
          reminderMinutes: _reminders,
          guests: _guests,
          source: existing.source,
          sourceOfTruth: existing.sourceOfTruth,
          deletedAt: existing.deletedAt,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now().toUtc(),
        );
        await repo.update(updated);
        await _remember(updated);
        await analytics.track(EventEdited(source: existing.source.name));
        await _trackDetails();
      } else if (_allDay) {
        final created = await repo.createAllDay(
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
          recurrenceRule: writeRule,
          recurrenceUntil: writeUntil,
        );
        final stored = created.copyWith(
          categoryId: _categoryId,
          reminderMinutes: _reminders,
          replaceReminders: true,
          guests: _guests,
          replaceGuests: true,
        );
        await repo.update(stored);
        await _remember(stored);
        await _trackDetails();
        await analytics.track(
          EventCreated(
            source: 'vrijdag',
            isAllDay: true,
            hasLocation: location != null,
          ),
        );
      } else {
        final created = await repo.createTimed(
          NewTimedEventDraft(
            title: title,
            startsAt: _startLocal.toUtc(),
            timezone: timezone,
            duration: _endLocal.difference(_startLocal),
            notes: notes,
            location: location,
            recurrenceRule: writeRule,
            recurrenceUntil: writeUntil,
          ),
        );
        final stored = created.copyWith(
          categoryId: _categoryId,
          reminderMinutes: _reminders,
          replaceReminders: true,
          guests: _guests,
          replaceGuests: true,
        );
        await repo.update(stored);
        await _remember(stored);
        await _trackDetails();
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

    final series =
        existing.seriesMaster ?? (existing.isRecurring ? existing : null);
    if (series != null && series.isRecurring) {
      final scope = await _askScope();
      if (scope == null || !mounted) {
        return;
      }
      if (scope == RecurrenceScope.all) {
        await _performSoftDelete(series, showUndo: false);
        return;
      }
      final occurrence =
          existing.timed?.startsAt.toLocal() ?? existing.allDay!.startDate;
      final plan = planRecurrenceEdit(
        scope: scope,
        occurrence: occurrence,
        existingExdates: series.recurrenceExdates,
        deleting: true,
      );
      final repo = ref.read(personalEventsRepositoryProvider);
      await repo.update(
        series.copyWith(
          recurrenceExdates: plan.exdates,
          recurrenceUntil: plan.replaceUntil
              ? plan.seriesUntil
              : series.recurrenceUntil,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      if (!mounted) {
        return;
      }
      ref.invalidate(todaysEventsProvider);
      ref.invalidate(dayEventsProvider);
      ref.invalidate(visibleEventsProvider);
      Navigator.of(context).pop(true);
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

  String _categoryName() {
    final id = _categoryId;
    if (id == null) {
      return context.l10n.weekDayEmpty;
    }
    final items = ref.read(eventCategoriesProvider).valueOrNull ?? const [];
    for (final item in items) {
      if (item.id == id) {
        return item.name;
      }
    }
    return context.l10n.weekDayEmpty;
  }

  Future<void> _pickCategory() async {
    final items = ref.read(eventCategoriesProvider).valueOrNull ?? const [];
    final picked = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(context.l10n.categoryEvent),
          children: [
            for (final item in items)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(item.id),
                child: Text(item.name),
              ),
          ],
        );
      },
    );
    if (picked == null) {
      return;
    }
    setState(() => _categoryId = picked == _categoryId ? null : picked);
  }

  static const reminderAskedKey = 'reminder_permission_asked';
  static const reminderOffKey = 'reminder_notifications_off';

  Future<void> _loadDefaultReminder() async {
    final minutes = await ref.read(defaultReminderProvider.future);
    final prefs = await SharedPreferences.getInstance();
    final off = prefs.getBool(reminderOffKey) ?? false;
    if (!mounted) {
      return;
    }
    setState(() {
      if (widget.existing == null && minutes != null) {
        _reminders = [minutes];
      }
      _notificationsOff = off;
    });
  }

  String _offsetLabel(AppLocalizations l10n, int minutes) {
    return switch (minutes) {
      0 => l10n.reminderAtTime,
      60 => l10n.reminderHour,
      1440 => l10n.reminderDay,
      _ => l10n.reminderMinutes(minutes),
    };
  }

  String _reminderLabel(AppLocalizations l10n) {
    if (_reminders.isEmpty) {
      return l10n.reminderNone;
    }
    return _reminders.map((minutes) => _offsetLabel(l10n, minutes)).join(', ');
  }

  Future<void> _pickReminders() async {
    final l10n = context.l10n;
    final selected = {..._reminders};
    final picked = await showDialog<Set<int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(l10n.reminderTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final minutes in reminderPresetMinutes)
                    CheckboxListTile(
                      value: selected.contains(minutes),
                      title: Text(_offsetLabel(l10n, minutes)),
                      onChanged: (value) {
                        setLocal(() {
                          if (value ?? false) {
                            selected.add(minutes);
                          } else {
                            selected.remove(minutes);
                          }
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(<int>{}),
                  child: Text(l10n.reminderNone),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(selected),
                  child: Text(l10n.commonSave),
                ),
              ],
            );
          },
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _reminders = picked.toList()..sort());
    if (picked.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(reminderAskedKey) ?? false) {
      return;
    }
    await prefs.setBool(reminderAskedKey, true);
    if (!mounted) {
      return;
    }
    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: PermissionExplainer(
          body: l10n.reminderAsk,
          actionLabel: l10n.reminderAllow,
          notNowLabel: l10n.reminderNotNow,
          onContinue: () => Navigator.of(context).pop(true),
          onNotNow: () => Navigator.of(context).pop(false),
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    if (allow != true) {
      await prefs.setBool(reminderOffKey, true);
      setState(() => _notificationsOff = true);
      return;
    }
    final granted = await ref
        .read(reminderNotificationsProvider)
        .requestPermission();
    await prefs.setBool(reminderOffKey, !granted);
    if (mounted) {
      setState(() => _notificationsOff = !granted);
    }
  }

  Future<void> _editGuests() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.guestTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: l10n.guestHint),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(l10n.guestAdd),
            ),
          ],
        );
      },
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || !mounted) {
      return;
    }
    setState(() => _guests = [..._guests, trimmed]);
  }

  String _countBucket(int count) => count <= 0
      ? '0'
      : count == 1
      ? '1'
      : '2+';

  Future<void> _trackDetails() async {
    final analytics = ref.read(analyticsProvider);
    final hadReminders = widget.existing?.reminderMinutes.isNotEmpty ?? false;
    final hadGuests = widget.existing?.guests.isNotEmpty ?? false;
    if (_reminders.isNotEmpty || hadReminders) {
      await analytics.track(
        ReminderSaved(countBucket: _countBucket(_reminders.length)),
      );
    }
    if (_guests.isNotEmpty || hadGuests) {
      await analytics.track(
        GuestsSaved(countBucket: _countBucket(_guests.length)),
      );
    }
  }

  Future<void> _remember(PersonalEvent saved) async {
    final notifications = ref.read(reminderNotificationsProvider);
    if (_notificationsOff || saved.reminderMinutes.isEmpty) {
      await notifications.clear(saved.id);
      return;
    }
    final anchor = reminderAnchor(
      startsAt: saved.timed?.startsAt,
      allDayStart: saved.allDay?.startDate,
    );
    final now = DateTime.now().toUtc();
    final notices = <ReminderNotice>[
      for (final minutes in saved.reminderMinutes)
        if (!anchor.subtract(Duration(minutes: minutes)).isBefore(now))
          ReminderNotice(
            id: reminderNotificationId(saved.id, minutes),
            when: anchor.subtract(Duration(minutes: minutes)),
            title: saved.title,
          ),
    ];
    try {
      await notifications.replace(
        eventId: saved.id,
        channelName: context.l10n.reminderChannel,
        notices: notices,
      );
    } on Object {
      if (mounted) {
        setState(() => _notificationsOff = true);
      }
    }
  }

  Future<void> _share() async {
    final existing = widget.existing;
    if (existing == null || !_viewing) {
      return;
    }
    final l10n = context.l10n;
    final text = eventShareText(
      existing,
      allDayLabel: l10n.dayTagAllDay,
      untitled: l10n.eventUntitled,
    );
    final ics = eventToIcs(existing);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/vrijdag-${existing.id}.ics');
    await file.writeAsString(ics);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: [XFile(file.path, mimeType: 'text/calendar')],
      ),
    );
    if (!mounted) {
      return;
    }
    await ref.read(analyticsProvider).track(const EventShared(format: 'ics'));
  }

  Future<RecurrenceScope?> _askScope() {
    final l10n = context.l10n;
    return showDialog<RecurrenceScope>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.calendarRecurrenceScopeTitle),
          children: [
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(context).pop(RecurrenceScope.thisEvent),
              child: Text(l10n.calendarRecurrenceThisOccurrence),
            ),
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(context).pop(RecurrenceScope.thisAndFollowing),
              child: Text(l10n.calendarRecurrenceThisAndFollowing),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(RecurrenceScope.all),
              child: Text(l10n.calendarRecurrenceAllEvents),
            ),
          ],
        );
      },
    );
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
          if (_viewing) ...[
            TextButton(onPressed: _share, child: Text(l10n.eventShare)),
            TextButton(
              onPressed: () => setState(() => _viewing = false),
              child: Text(l10n.eventEdit),
            ),
          ] else
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
            if (!_viewing || _reminders.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.reminderTitle),
                subtitle: Text(
                  _notificationsOff ? l10n.reminderOff : _reminderLabel(l10n),
                ),
                onTap: _viewing || _saving ? null : _pickReminders,
              ),
            if (!_viewing || _guests.isNotEmpty) ...[
              Text(l10n.guestTitle),
              Wrap(
                spacing: 8,
                children: [
                  for (final guest in _guests)
                    InputChip(
                      label: Text(guest),
                      onDeleted: _viewing || _saving
                          ? null
                          : () {
                              setState(() {
                                final next = [..._guests]..remove(guest);
                                _guests = next;
                              });
                            },
                    ),
                ],
              ),
              if (!_viewing)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _saving ? null : _editGuests,
                    child: Text(l10n.guestAdd),
                  ),
                ),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.categoryEvent),
              subtitle: Text(_categoryName()),
              onTap: _viewing || _saving ? null : _pickCategory,
            ),
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
