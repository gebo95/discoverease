import 'package:flutter/material.dart';

/// Pick exactly one option (or none, when [isRequired] is false) from a row of
/// buttons. Tapping the chosen one again clears it.
class SingleChoiceField extends FormField<String> {
  SingleChoiceField({
    super.key,
    required String label,
    required List<String> options,
    required String value,
    required ValueChanged<String> onChanged,
    String? hint,
    Map<String, String> captions = const {},
    bool isRequired = false,
  }) : super(
         initialValue: value,
         validator: (chosen) =>
             isRequired && !options.contains(chosen) ? 'Choose one.' : null,
         builder: (state) {
           final chosen = value;
           return _FieldFrame(
             label: label,
             hint: hint,
             error: state.errorText,
             footer: chosen.isNotEmpty && captions[chosen] != null
                 ? captions[chosen]
                 : null,
             child: Wrap(
               spacing: 8,
               runSpacing: 4,
               children: [
                 for (final option in options)
                   ChoiceChip(
                     label: Text(option),
                     selected: chosen == option,
                     onSelected: (selected) {
                       final next = selected || isRequired ? option : '';
                       state.didChange(next);
                       onChanged(next);
                     },
                   ),
               ],
             ),
           );
         },
       );
}

/// Pick up to [max] options from a row of buttons. Once the limit is reached
/// the unchosen ones are disabled until something is removed.
class MultiChoiceField extends StatelessWidget {
  const MultiChoiceField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.max,
    this.hint,
  });

  final String label;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final int max;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final full = selected.length >= max;
    // Keep a saved value that is no longer in the list visible and removable.
    final shown = [
      ...selected.where((value) => !options.contains(value)),
      ...options,
    ];
    return _FieldFrame(
      label: label,
      hint: hint,
      footer: '${selected.length} of $max chosen',
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final option in shown)
            FilterChip(
              label: Text(option),
              selected: selected.contains(option),
              onSelected: (on) {
                if (on && full) return;
                final next = [...selected];
                on ? next.add(option) : next.remove(option);
                onChanged(next);
              },
            ),
        ],
      ),
    );
  }
}

class _FieldFrame extends StatelessWidget {
  const _FieldFrame({
    required this.label,
    required this.child,
    this.hint,
    this.error,
    this.footer,
  });

  final String label;
  final String? hint;
  final String? error;
  final String? footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          if (hint != null)
            Text(hint!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          child,
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            )
          else if (footer != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(footer!, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}
