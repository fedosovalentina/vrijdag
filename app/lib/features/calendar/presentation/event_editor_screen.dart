import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/auth/domain/profile_defaults.dart';
import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';

/// Create or edit a personal event (utilitarian F-004 UI).
class EventEditorScreen extends ConsumerStatefulWidget {
  const EventEditorScreen({super.key, this.existing});

  final PersonalEvent? existing;

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
  var _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _location = TextEditingController(text: existing?.location ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');

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
      _startLocal = _roundToNextQuarter(DateTime.now());
      _endLocal = _startLocal.add(defaultTimedEventDuration);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
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
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = l10n.calendarTitleRequired);
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

      if (_isEdit) {
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

  String _formatDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    if (_allDay) {
      return '${two(value.day)}.${two(value.month)}.${value.year}';
    }
    return '${two(value.day)}.${two(value.month)}.${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.calendarEditEvent : l10n.calendarNewEvent),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: l10n.calendarTitleLabel),
            textCapitalization: TextCapitalization.sentences,
            enabled: !_saving,
          ),
          const SizedBox(height: 8),
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
                        _endLocal = _startLocal.add(defaultTimedEventDuration);
                      }
                    });
                  },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.calendarStartsLabel),
            subtitle: Text(_formatDateTime(_startLocal)),
            onTap: _saving ? null : _pickStart,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.calendarEndsLabel),
            subtitle: Text(_formatDateTime(_endLocal)),
            onTap: _saving ? null : _pickEnd,
          ),
          TextField(
            controller: _location,
            decoration: InputDecoration(labelText: l10n.calendarLocationLabel),
            enabled: !_saving,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            decoration: InputDecoration(labelText: l10n.calendarNotesLabel),
            maxLines: 3,
            enabled: !_saving,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }
}
