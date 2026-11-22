import 'package:flutter/material.dart';

import '../../../shared/utils/hours_format.dart';

int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;
TimeOfDay _timeOf(int minutes) =>
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

/// Opening hours picked with day buttons and time pickers. [onChanged] gets
/// the readable text, or [initialText] again while nothing complete is set.
class HoursField extends StatefulWidget {
  const HoursField({
    super.key,
    required this.initialText,
    required this.onChanged,
  });

  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  State<HoursField> createState() => _HoursFieldState();
}

class _HoursFieldState extends State<HoursField> {
  final List<HoursRow> _rows = [];

  void _emit() {
    final text = formatHours(_rows);
    widget.onChanged(text.isEmpty ? widget.initialText : text);
  }

  Future<int?> _pick(int? current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOf(current ?? 9 * 60),
    );
    return picked == null ? null : _minutes(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hours', style: theme.textTheme.titleSmall),
          Text(
            _rows.isEmpty && widget.initialText.isNotEmpty
                ? 'Now: ${widget.initialText}. Add hours below to replace it.'
                : 'Choose the days, then when you open and close (optional).',
            style: theme.textTheme.bodySmall,
          ),
          for (var i = 0; i < _rows.length; i++) _row(i),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _rows.add(const HoursRow(days: {}))),
              icon: const Icon(Icons.add),
              label: Text(_rows.isEmpty ? 'Add hours' : 'Add other hours'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(int index) {
    final row = _rows[index];
    void update(HoursRow next) {
      setState(() => _rows[index] = next);
      _emit();
    }

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              children: [
                for (var d = 0; d < 7; d++)
                  FilterChip(
                    label: Text(dayNames[d]),
                    selected: row.days.contains(d),
                    onSelected: (on) {
                      final days = {...row.days};
                      on ? days.add(d) : days.remove(d);
                      update(HoursRow(days: days, opens: row.opens, closes: row.closes));
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final value = await _pick(row.opens);
                      if (value != null) {
                        update(HoursRow(days: row.days, opens: value, closes: row.closes));
                      }
                    },
                    child: Text(row.opens == null ? 'Opens' : formatClock(row.opens!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final value = await _pick(row.closes ?? (row.opens ?? 9 * 60) + 8 * 60);
                      if (value != null) {
                        update(HoursRow(days: row.days, opens: row.opens, closes: value));
                      }
                    },
                    child: Text(row.closes == null ? 'Closes' : formatClock(row.closes!)),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() => _rows.removeAt(index));
                    _emit();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "When it happens" picked as one date, a date range, or a weekly pattern.
class ScheduleField extends StatefulWidget {
  const ScheduleField({
    super.key,
    required this.initialText,
    required this.onChanged,
  });

  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  State<ScheduleField> createState() => _ScheduleFieldState();
}

class _ScheduleFieldState extends State<ScheduleField> {
  ScheduleChoice _choice = const ScheduleChoice();

  void _set(ScheduleChoice next) {
    setState(() => _choice = next);
    final text = formatSchedule(next);
    widget.onChanged(text.isEmpty ? widget.initialText : text);
  }

  ScheduleChoice _copy({
    ScheduleKind? kind,
    DateTime? start,
    DateTime? end,
    Set<int>? days,
    int? time,
    bool clearTime = false,
  }) => ScheduleChoice(
    kind: kind ?? _choice.kind,
    start: start ?? _choice.start,
    end: end ?? _choice.end,
    days: days ?? _choice.days,
    time: clearTime ? null : time ?? _choice.time,
  );

  Future<DateTime?> _pickDate(DateTime? current) {
    final today = DateUtils.dateOnly(DateTime.now());
    return showDatePicker(
      context: context,
      initialDate: current != null && !current.isBefore(today) ? current : today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind = _choice.kind;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('When it happens', style: theme.textTheme.titleSmall),
          Text(
            kind == ScheduleKind.none && widget.initialText.isNotEmpty
                ? 'Now: ${widget.initialText}. Pick below to replace it.'
                : 'Only for events with set dates (optional).',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final option in const {
                ScheduleKind.date: 'One date',
                ScheduleKind.range: 'Date range',
                ScheduleKind.weekly: 'Every week',
              }.entries)
                ChoiceChip(
                  label: Text(option.value),
                  selected: kind == option.key,
                  onSelected: (on) => _set(
                    on ? _copy(kind: option.key) : const ScheduleChoice(),
                  ),
                ),
            ],
          ),
          if (kind == ScheduleKind.date || kind == ScheduleKind.range)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(
                        _choice.start == null
                            ? (kind == ScheduleKind.date ? 'Pick date' : 'Starts')
                            : formatDate(_choice.start!),
                      ),
                      onPressed: () async {
                        final date = await _pickDate(_choice.start);
                        if (date != null) _set(_copy(start: date));
                      },
                    ),
                  ),
                  if (kind == ScheduleKind.range) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event),
                        label: Text(
                          _choice.end == null ? 'Ends' : formatDate(_choice.end!),
                        ),
                        onPressed: () async {
                          final date = await _pickDate(_choice.end ?? _choice.start);
                          if (date != null) _set(_copy(end: date));
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (kind == ScheduleKind.range &&
              _choice.start != null &&
              _choice.end != null &&
              _choice.end!.isBefore(_choice.start!))
            Text(
              'The end date must not be before the start.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          if (kind == ScheduleKind.weekly)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                children: [
                  for (var d = 0; d < 7; d++)
                    FilterChip(
                      label: Text(dayNames[d]),
                      selected: _choice.days.contains(d),
                      onSelected: (on) {
                        final days = {..._choice.days};
                        on ? days.add(d) : days.remove(d);
                        _set(_copy(days: days));
                      },
                    ),
                ],
              ),
            ),
          if (kind != ScheduleKind.none)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      _choice.time == null ? 'Add start time' : formatClock(_choice.time!),
                    ),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _timeOf(_choice.time ?? 19 * 60),
                      );
                      if (picked != null) _set(_copy(time: _minutes(picked)));
                    },
                  ),
                  if (_choice.time != null)
                    IconButton(
                      tooltip: 'Remove time',
                      icon: const Icon(Icons.close),
                      onPressed: () => _set(_copy(clearTime: true)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
