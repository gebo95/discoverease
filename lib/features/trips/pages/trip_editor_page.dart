import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/destination.dart';
import '../../../models/trip.dart';
import '../../../repositories/destination_repository.dart';
import '../../../repositories/trip_repository.dart';
import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_radius.dart';
import '../../../shared/theme/de_spacing.dart';

class TripEditorPage extends StatefulWidget {
  final Trip? trip;

  const TripEditorPage({super.key, this.trip});

  @override
  State<TripEditorPage> createState() => _TripEditorPageState();
}

class _TripEditorPageState extends State<TripEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late String? _destinationId;
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _isEditing => widget.trip != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.trip?.title ?? '');
    _destinationId = widget.trip?.destinationId;
    _startDate = widget.trip?.startDate;
    _endDate = widget.trip?.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destinations = context.read<DestinationRepository>().getAll();
    if (_destinationId == null && _isEditing) {
      _destinationId = _destinationIdForLegacyTrip(destinations, widget.trip!);
    }
    _destinationId ??= context
        .read<DestinationRepository>()
        .currentDestination
        .id;

    return Scaffold(
      backgroundColor: DEColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit trip' : 'Create a trip'),
        backgroundColor: DEColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(DESpacing.md),
          children: [
            Text(
              _isEditing ? 'Update your plans' : 'Where to next?',
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a destination. Add dates now or leave them flexible.',
              style: TextStyle(color: DEColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: DESpacing.lg),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Trip name (optional)',
                hintText: 'e.g. Tokyo long weekend',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              maxLength: 48,
            ),
            const SizedBox(height: DESpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _destinationId,
              decoration: const InputDecoration(
                labelText: 'Destination',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              items: destinations
                  .map(
                    (destination) => DropdownMenuItem(
                      value: destination.id,
                      child: Text(
                        '${destination.flagEmoji}  ${destination.name}, '
                        '${destination.country}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _destinationId = value),
              validator: (value) => value == null ? 'Choose a destination.' : null,
            ),
            const SizedBox(height: DESpacing.xl),
            const Text(
              'Dates',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            const Text(
              'Optional. You can plan days before your dates are final.',
              style: TextStyle(color: DEColors.textSecondary),
            ),
            const SizedBox(height: DESpacing.md),
            OutlinedButton.icon(
              onPressed: _chooseDates,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_dateLabel(context)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.centerLeft,
              ),
            ),
            if (_startDate != null || _endDate != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _startDate = null;
                    _endDate = null;
                  }),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Keep dates flexible'),
                ),
              ),
            if (_isEditing && widget.trip!.plannedExperiences > 0) ...[
              const SizedBox(height: DESpacing.sm),
              Container(
                padding: const EdgeInsets.all(DESpacing.md),
                decoration: BoxDecoration(
                  color: DEColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(DERadius.large),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: DEColors.primary),
                    SizedBox(width: DESpacing.sm),
                    Expanded(
                      child: Text(
                        'Your planned experiences stay with this trip. If you '
                        'shorten it, plans from removed days move to the final day.',
                        style: TextStyle(color: DEColors.textSecondary, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: DESpacing.xl),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded),
              label: Text(_isEditing ? 'Save changes' : 'Create trip'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DERadius.pill),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseDates() async {
    final today = DateTime.now();
    final existingRange = _startDate != null && _endDate != null
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : null;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 10),
      lastDate: DateTime(today.year + 6),
      initialDateRange: existingRange,
      helpText: 'Choose trip dates',
      saveText: 'Apply dates',
    );
    if (!mounted || range == null) return;
    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });
  }

  String _dateLabel(BuildContext context) {
    if (_startDate == null || _endDate == null) return 'Add a date range';
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(_startDate!)} – '
        '${localizations.formatMediumDate(_endDate!)}';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final destinationRepository = context.read<DestinationRepository>();
    final destination = destinationRepository.getById(_destinationId!);
    if (destination == null) return;

    final tripRepository = context.read<TripRepository>();
    final tripTitle = _titleController.text.trim().isEmpty
        ? '${destination.name} trip'
        : _titleController.text.trim();
    final trip = _isEditing
        ? tripRepository.updateCurrentTrip(
            title: tripTitle,
            destinationId: destination.id,
            destination: destination.country,
            startDate: _startDate,
            endDate: _endDate,
          )
        : tripRepository.createTrip(
            title: tripTitle,
            destinationId: destination.id,
            destination: destination.country,
            startDate: _startDate,
            endDate: _endDate,
          );

    if (_isEditing) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, trip);
  }

  String? _destinationIdForLegacyTrip(List<Destination> destinations, Trip trip) {
    for (final destination in destinations) {
      if (destination.country.toLowerCase() == trip.destination.toLowerCase() ||
          destination.name.toLowerCase() == trip.destination.toLowerCase()) {
        return destination.id;
      }
    }
    return destinations.isEmpty ? null : destinations.first.id;
  }
}
