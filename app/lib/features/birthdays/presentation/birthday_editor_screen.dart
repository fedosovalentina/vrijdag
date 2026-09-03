import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/birthdays/presentation/birthday_providers.dart';

class BirthdayEditorScreen extends ConsumerStatefulWidget {
  const BirthdayEditorScreen({super.key, this.existing});

  final Birthday? existing;

  @override
  ConsumerState<BirthdayEditorScreen> createState() =>
      _BirthdayEditorScreenState();
}

class _BirthdayEditorScreenState extends ConsumerState<BirthdayEditorScreen> {
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late final TextEditingController _year;
  late int _month;
  late int _day;
  var _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _year = TextEditingController(
      text: existing?.year == null ? '' : '${existing!.year}',
    );
    _month = existing?.month ?? DateTime.now().month;
    _day = existing?.day ?? DateTime.now().day;
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.birthdayNameRequired);
      return;
    }

    final yearText = _year.text.trim();
    final year = yearText.isEmpty ? null : int.tryParse(yearText);
    if (yearText.isNotEmpty && year == null) {
      setState(() => _error = l10n.birthdayInvalidDate);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(birthdaysRepositoryProvider);
      final analytics = ref.read(analyticsProvider);
      final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();

      if (_isEdit) {
        final existing = widget.existing!;
        await repo.update(
          Birthday(
            id: existing.id,
            userId: existing.userId,
            name: name,
            month: _month,
            day: _day,
            year: year,
            notes: notes,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      } else {
        await repo.create(
          name: name,
          month: _month,
          day: _day,
          year: year,
          notes: notes,
        );
        await analytics.track(const BirthdayCreated());
      }

      if (!mounted) {
        return;
      }
      ref.invalidate(birthdaysListProvider);
      Navigator.of(context).pop(true);
    } on ArgumentError {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = l10n.birthdayInvalidDate;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = l10n.birthdaySaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.birthdayEdit : l10n.birthdayNew),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l10n.birthdayNameLabel),
            textCapitalization: TextCapitalization.words,
            enabled: !_saving,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use
                  value: _month,
                  decoration: InputDecoration(
                    labelText: l10n.birthdayMonthLabel,
                  ),
                  items: [
                    for (var m = 1; m <= 12; m++)
                      DropdownMenuItem(value: m, child: Text('$m')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _month = value);
                          }
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use
                  value: _day,
                  decoration: InputDecoration(labelText: l10n.birthdayDayLabel),
                  items: [
                    for (var d = 1; d <= 31; d++)
                      DropdownMenuItem(value: d, child: Text('$d')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _day = value);
                          }
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _year,
            decoration: InputDecoration(labelText: l10n.birthdayYearLabel),
            keyboardType: TextInputType.number,
            enabled: !_saving,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: InputDecoration(labelText: l10n.birthdayNotesLabel),
            maxLines: 2,
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
