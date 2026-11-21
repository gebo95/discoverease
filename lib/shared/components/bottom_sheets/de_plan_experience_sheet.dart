import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/trip_reservation.dart';
import '../../../models/trip_section.dart';
import '../../../models/trip_schedule_validation.dart';
import '../pickers/de_day_picker.dart';
import '../pickers/de_time_section_picker.dart';
import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

typedef PlanExperienceCallback = void Function(
  int dayIndex,
  TripSection section, {
  TimeOfDay? time,
  TimeOfDay? closingTime,
  int? travelMinutes,
  TripReservation? reservation,
  double? estimatedCost,
  String? notes,
});

void showDEPlanExperienceSheet(
  BuildContext context, {
  required String experienceTitle,
  required List<String> days,
  required PlanExperienceCallback onPlan,
  int initialDayIndex = 0,
  String? Function(int dayIndex)? dayWarning,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DEPlanExperienceSheet(
      experienceTitle: experienceTitle,
      days: days,
      onPlan: onPlan,
      initialDayIndex: initialDayIndex,
      dayWarning: dayWarning,
    ),
  );
}

class DEPlanExperienceSheet extends StatefulWidget {
  final String experienceTitle;
  final List<String> days;
  final PlanExperienceCallback onPlan;
  final int initialDayIndex;

  /// Optional heads-up for the chosen day (for example, the experience ends
  /// before it). It never blocks adding.
  final String? Function(int dayIndex)? dayWarning;

  const DEPlanExperienceSheet({
    super.key,
    required this.experienceTitle,
    required this.days,
    required this.onPlan,
    this.initialDayIndex = 0,
    this.dayWarning,
  });

  @override
  State<DEPlanExperienceSheet> createState() => _DEPlanExperienceSheetState();
}

class _DEPlanExperienceSheetState extends State<DEPlanExperienceSheet> {
  int selectedDay = 0;
  TripSection? selectedSection;
  TimeOfDay? selectedTime;
  TimeOfDay? selectedClosingTime;
  bool hasReservation = false;
  String? _travelMinutesError;
  String? _costError;
  final _travelMinutesController = TextEditingController();
  final _costController = TextEditingController();
  final _experienceNotesController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _ticketUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedDay = widget.days.isEmpty
        ? 0
        : widget.initialDayIndex.clamp(0, widget.days.length - 1);
  }

  String? _dayNote() =>
      widget.days.isEmpty ? null : widget.dayWarning?.call(selectedDay);

  @override
  void dispose() {
    _travelMinutesController.dispose();
    _costController.dispose();
    _experienceNotesController.dispose();
    _confirmationController.dispose();
    _ticketUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        DESpacing.lg,
        DESpacing.lg,
        DESpacing.lg,
        DESpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DERadius.extraLarge),
        ),
      ),
      // Transparent Material gives ListTiles a valid ink surface below the
      // decorated container, which would otherwise hide their splash/background.
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: DEColors.border,
                    borderRadius: BorderRadius.circular(DERadius.pill),
                  ),
                ),
              ),

              const SizedBox(height: DESpacing.lg),

              Text(
                widget.experienceTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "When would you like to enjoy this?",
                style: TextStyle(color: DEColors.textSecondary),
              ),

              const SizedBox(height: DESpacing.xl),

              const Text(
                "Choose a day",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: DESpacing.sm),

              DEDayPicker(
                days: widget.days,
                selectedIndex: selectedDay,
                onSelected: (index) {
                  setState(() {
                    selectedDay = index;
                  });
                },
              ),

              if (_dayNote() case final dayNote?) ...[
                const SizedBox(height: DESpacing.sm),
                _PlanWarning(message: dayNote),
              ],

              const SizedBox(height: DESpacing.xl),

              const Text(
                "Choose a time",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: DESpacing.sm),

              DETimeSectionPicker(
                selectedSection: selectedSection,
                onSelected: (section) {
                  setState(() {
                    selectedSection = section;
                  });
                },
              ),

              if (TripScheduleValidation.warningFor(selectedSection, selectedTime)
                  case final warning?) ...[
                const SizedBox(height: DESpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DESpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(DERadius.medium),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(warning, style: const TextStyle(height: 1.3))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: DESpacing.md),

              OutlinedButton.icon(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime ?? TimeOfDay.now(),
                  );
                  if (!mounted || time == null) return;
                  setState(() => selectedTime = time);
                },
                icon: const Icon(Icons.schedule_rounded),
                label: Text(
                  selectedTime == null
                      ? 'Add start time'
                      : 'Start time: ${selectedTime!.format(context)}',
                ),
              ),

              const SizedBox(height: DESpacing.md),

              OutlinedButton.icon(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedClosingTime ?? TimeOfDay.now(),
                    helpText: 'When does this place close?',
                  );
                  if (!mounted || time == null) return;
                  setState(() => selectedClosingTime = time);
                },
                icon: const Icon(Icons.storefront_outlined),
                label: Text(
                  selectedClosingTime == null
                      ? 'Add closing time (optional)'
                      : 'Closes at: ${selectedClosingTime!.format(context)}',
                ),
              ),

              const SizedBox(height: DESpacing.md),

              TextField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Estimated cost for this experience',
                  prefixText: '\$ ',
                  hintText: 'Optional',
                  errorText: _costError,
                ),
                onChanged: (_) => setState(() => _costError = null),
              ),

              const SizedBox(height: DESpacing.sm),

              TextField(
                controller: _experienceNotesController,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note for this experience',
                  hintText: 'Optional reminder or detail',
                ),
              ),

              const SizedBox(height: DESpacing.md),

              TextField(
                controller: _travelMinutesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Travel time to get there (minutes)',
                  hintText: 'Optional',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  helperText: 'Leave blank if you do not know yet.',
                ),
                onChanged: (_) => setState(() => _travelMinutesError = null),
              ),
              if (_travelMinutesError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _travelMinutesError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),

              const SizedBox(height: DESpacing.sm),
              const Text(
                'Start times and travel estimates let Companion remind you when to leave.',
                style: TextStyle(color: DEColors.textSecondary, height: 1.4),
              ),

              const SizedBox(height: DESpacing.md),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('I have a reservation or ticket'),
                value: hasReservation,
                onChanged: (value) => setState(() => hasReservation = value),
              ),
              if (hasReservation) ...[
                TextField(
                  controller: _confirmationController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Confirmation number',
                    hintText: 'Optional',
                  ),
                ),
                const SizedBox(height: DESpacing.sm),
                TextField(
                  controller: _ticketUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Ticket link',
                    hintText: 'Optional',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: DESpacing.sm),
                const Text(
                  'Companion will remind you 1 hour before when a start time is set.',
                  style: TextStyle(color: DEColors.textSecondary, height: 1.4),
                ),
              ],

              const SizedBox(height: DESpacing.xl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedSection == null
                      ? null
                      : () {
                          final travelText = _travelMinutesController.text.trim();
                          final travelMinutes = travelText.isEmpty
                              ? null
                              : int.tryParse(travelText);
                          if (travelText.isNotEmpty &&
                              (travelMinutes == null || travelMinutes <= 0)) {
                            setState(() {
                              _travelMinutesError =
                                  'Enter a travel time greater than 0.';
                            });
                            return;
                          }
                          final costText = _costController.text.trim();
                          final estimatedCost = costText.isEmpty
                              ? null
                              : double.tryParse(costText.replaceAll(',', ''));
                          if (costText.isNotEmpty &&
                              (estimatedCost == null ||
                                  !estimatedCost.isFinite ||
                                  estimatedCost < 0)) {
                            setState(() {
                              _costError = 'Enter a valid cost of 0 or more.';
                            });
                            return;
                          }

                          Navigator.pop(context);
                          widget.onPlan(
                            selectedDay,
                            selectedSection!,
                            time: selectedTime,
                            closingTime: selectedClosingTime,
                            travelMinutes: travelMinutes,
                            reservation: hasReservation
                                ? TripReservation(
                                    type: TripReservationType.other,
                                    confirmationNumber: _optionalText(
                                      _confirmationController.text,
                                    ),
                                    ticketUrl: _optionalText(
                                      _ticketUrlController.text,
                                    ),
                                  )
                                : null,
                            estimatedCost: estimatedCost,
                            notes: _experienceNotesController.text,
                          );
                        },
                  child: const Text("Plan Experience"),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

}

class _PlanWarning extends StatelessWidget {
  const _PlanWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DESpacing.sm),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(DERadius.medium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: Colors.deepOrange),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(height: 1.3))),
        ],
      ),
    );
  }
}
