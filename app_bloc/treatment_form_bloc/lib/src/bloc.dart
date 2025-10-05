import 'package:app_database/app_database.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'event.dart';
part 'state.dart';

/// {@template treatment_form_event}
/// Base class for all TreatmentForm events.
/// {@endtemplate}
sealed class TreatmentFormEvent {
  /// {@macro treatment_form_event}
  const TreatmentFormEvent();
}

/// {@template treatment_form_event_title_changed}
/// Event triggered when the treatment title changes.
/// {@endtemplate}
final class TreatmentFormTitleChanged extends TreatmentFormEvent {
  /// {@macro treatment_form_event_title_changed}
  final String title;

  /// {@macro treatment_form_event_title_changed}
  const TreatmentFormTitleChanged(this.title);
}

/// {@template treatment_form_event_diagnosis_changed}
/// Event triggered when the diagnosis changes.
/// {@endtemplate}
final class TreatmentFormDiagnosisChanged extends TreatmentFormEvent {
  /// {@macro treatment_form_event_diagnosis_changed}
  final String diagnosis;

  /// {@macro treatment_form_event_diagnosis_changed}
  const TreatmentFormDiagnosisChanged(this.diagnosis);
}

/// {@template treatment_form_event_start_date_changed}
/// Event triggered when the start date changes.
/// {@endtemplate}
final class TreatmentFormStartDateChanged extends TreatmentFormEvent {
  /// {@macro treatment_form_event_start_date_changed}
  final DateTime? startDate;

  /// {@macro treatment_form_event_start_date_changed}
  const TreatmentFormStartDateChanged(this.startDate);
}

/// {@template treatment_form_event_end_date_changed}
/// Event triggered when the end date changes.
/// {@endtemplate}
final class TreatmentFormEndDateChanged extends TreatmentFormEvent {
  /// {@macro treatment_form_event_end_date_changed}
  final DateTime? endDate;

  /// {@macro treatment_form_event_end_date_changed}
  const TreatmentFormEndDateChanged(this.endDate);
}

/// {@template treatment_form_event_reset}
/// Event to reset the form to initial state.
/// {@endtemplate}
final class TreatmentFormReset extends TreatmentFormEvent {
  /// {@macro treatment_form_event_reset}
  const TreatmentFormReset();
}

/// {@template treatment_form_event_populate}
/// Event to populate the form with existing treatment data (for editing).
/// {@endtemplate}
final class TreatmentFormPopulate extends TreatmentFormEvent {
  /// {@macro treatment_form_event_populate}
  final Treatment treatment;

  /// {@macro treatment_form_event_populate}
  const TreatmentFormPopulate(this.treatment);
}

/// {@template treatment_form_bloc}
/// TreatmentFormBLoC handles Treatment form related business logic.
/// {@endtemplate}
class TreatmentFormBloc extends Bloc<TreatmentFormEvent, TreatmentFormState> {
  /// {@macro treatment_form_bloc}
  TreatmentFormBloc() : super(TreatmentFormState.initial()) {
    on<TreatmentFormTitleChanged>(_onTitleChanged);
    on<TreatmentFormDiagnosisChanged>(_onDiagnosisChanged);
    on<TreatmentFormStartDateChanged>(_onStartDateChanged);
    on<TreatmentFormEndDateChanged>(_onEndDateChanged);
    on<TreatmentFormReset>(_onReset);
    on<TreatmentFormPopulate>(_onPopulate);
  }

  /// Handles title changes
  void _onTitleChanged(
    TreatmentFormTitleChanged event,
    Emitter<TreatmentFormState> emit,
  ) {
    final isTitleValid = event.title.trim().isNotEmpty;
    final isFormValid = _validateForm(
      title: event.title,
      diagnosis: state.diagnosis,
      startDate: state.startDate,
    );

    emit(state.copyWith(
      title: event.title,
      isTitleValid: isTitleValid,
      isFormValid: isFormValid,
    ));
  }

  /// Handles diagnosis changes
  void _onDiagnosisChanged(
    TreatmentFormDiagnosisChanged event,
    Emitter<TreatmentFormState> emit,
  ) {
    final isDiagnosisValid = event.diagnosis.trim().isNotEmpty;
    final isFormValid = _validateForm(
      title: state.title,
      diagnosis: event.diagnosis,
      startDate: state.startDate,
    );

    emit(state.copyWith(
      diagnosis: event.diagnosis,
      isDiagnosisValid: isDiagnosisValid,
      isFormValid: isFormValid,
    ));
  }

  /// Handles start date changes
  void _onStartDateChanged(
    TreatmentFormStartDateChanged event,
    Emitter<TreatmentFormState> emit,
  ) {
    DateTime? newEndDate = state.endDate;
    // If end date is before start date, clear it
    if (event.startDate != null && state.endDate != null && state.endDate!.isBefore(event.startDate!)) {
      newEndDate = null;
    }

    final isStartDateValid = event.startDate != null;
    final isFormValid = _validateForm(
      title: state.title,
      diagnosis: state.diagnosis,
      startDate: event.startDate,
    );

    emit(state.copyWith(
      startDate: event.startDate,
      endDate: newEndDate,
      isStartDateValid: isStartDateValid,
      isFormValid: isFormValid,
    ));
  }

  /// Handles end date changes
  void _onEndDateChanged(
    TreatmentFormEndDateChanged event,
    Emitter<TreatmentFormState> emit,
  ) {
    emit(state.copyWith(endDate: event.endDate));
  }

  /// Handles form reset
  void _onReset(
    TreatmentFormReset event,
    Emitter<TreatmentFormState> emit,
  ) {
    emit(TreatmentFormState.initial());
  }

  /// Handles form population with existing data
  void _onPopulate(
    TreatmentFormPopulate event,
    Emitter<TreatmentFormState> emit,
  ) {
    final isTitleValid = event.treatment.title.trim().isNotEmpty;
    final isDiagnosisValid = event.treatment.diagnosis.trim().isNotEmpty;
    final isStartDateValid = true; // Existing treatment always has start date
    final isFormValid = _validateForm(
      title: event.treatment.title,
      diagnosis: event.treatment.diagnosis,
      startDate: event.treatment.startDate,
    );

    emit(state.copyWith(
      title: event.treatment.title,
      diagnosis: event.treatment.diagnosis,
      startDate: event.treatment.startDate,
      endDate: event.treatment.endDate,
      isTitleValid: isTitleValid,
      isDiagnosisValid: isDiagnosisValid,
      isStartDateValid: isStartDateValid,
      isFormValid: isFormValid,
    ));
  }

  /// Validates the entire form
  bool _validateForm({
    required String title,
    required String diagnosis,
    required DateTime? startDate,
  }) {
    return title.trim().isNotEmpty &&
        diagnosis.trim().isNotEmpty &&
        startDate != null;
  }
}
