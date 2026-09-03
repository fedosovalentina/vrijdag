import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/auth/domain/profile_defaults.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = l10n.calendarTitleRequired);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final start = DateTime.now().toUtc();
      await ref
          .read(personalEventsRepositoryProvider)
          .createTimed(
            NewTimedEventDraft(
              title: title,
              startsAt: start,
              timezone: resolveDeviceTimezone(),
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              location: _location.text.trim().isEmpty
                  ? null
                  : _location.text.trim(),
            ),
          );
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarNewEvent)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: l10n.calendarTitleLabel),
            textCapitalization: TextCapitalization.sentences,
            enabled: !_saving,
          ),
          const SizedBox(height: 16),
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
