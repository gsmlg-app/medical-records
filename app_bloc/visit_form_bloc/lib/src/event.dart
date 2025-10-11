part of 'bloc.dart';

/// {@template visit_form_event}
/// Base class for all VisitForm events.
/// Note: With FormBloc, we primarily use direct method calls instead of events.
/// These events are kept for compatibility and potential future extensions.
/// {@endtemplate}
sealed class VisitFormEvent {
  /// {@macro visit_form_event}
  const VisitFormEvent();
}

/// {@template visit_form_event_populate}
/// Event to populate form with existing visit data.
/// {@endtemplate}
class VisitFormEventPopulate extends VisitFormEvent {
  /// {@macro visit_form_event_populate}
  final Visit visit;

  /// {@macro visit_form_event_populate}
  const VisitFormEventPopulate(this.visit);
}

/// {@template visit_form_event_reset}
/// Event to reset form to initial state.
/// {@endtemplate}
class VisitFormEventReset extends VisitFormEvent {
  /// {@macro visit_form_event_reset}
  const VisitFormEventReset();
}
