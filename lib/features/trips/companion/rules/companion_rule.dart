import 'package:discoverease/features/trips/companion/companion_context.dart';
import 'package:discoverease/features/trips/companion/companion_priority.dart';
import 'package:discoverease/features/trips/models/right_now_state.dart';

abstract interface class CompanionRule {
  const CompanionRule();

  CompanionPriority get priority;

  RightNowState? evaluate(CompanionContext context);
}
