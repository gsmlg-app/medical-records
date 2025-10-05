part of 'bloc.dart';

/// {@template treatment_form_status}
/// Enum representing the status of the treatment form.
/// {@endtemplate}
enum TreatmentFormStatus {
  /// {@macro treatment_form_status}
  initial,

  /// {@macro treatment_form_status}
  loading,

  /// {@macro treatment_form_status}
  completed,

  /// {@macro treatment_form_status}
  error
}

/// {@template treatment_form_state}
/// Represents the state of the treatment form.
/// {@endtemplate}
class TreatmentFormState extends Equatable {
  /// {@macro treatment_form_state}
  const TreatmentFormState({
    this.status = TreatmentFormStatus.initial,
    this.title = '',
    this.diagnosis = '',
    this.startDate,
    this.endDate,
    this.isTitleValid = false,
    this.isDiagnosisValid = false,
    this.isStartDateValid = false,
    this.isFormValid = false,
    this.error,
  });

  /// {@macro treatment_form_state}
  final TreatmentFormStatus status;

  /// {@macro treatment_form_state}
  final String title;

  /// {@macro treatment_form_state}
  final String diagnosis;

  /// {@macro treatment_form_state}
  final DateTime? startDate;

  /// {@macro treatment_form_state}
  final DateTime? endDate;

  /// {@macro treatment_form_state}
  final bool isTitleValid;

  /// {@macro treatment_form_state}
  final bool isDiagnosisValid;

  /// {@macro treatment_form_state}
  final bool isStartDateValid;

  /// {@macro treatment_form_state}
  final bool isFormValid;

  /// {@macro treatment_form_state}
  final String? error;

  /// {@macro treatment_form_state}
  factory TreatmentFormState.initial() {
    return const TreatmentFormState();
  }

  /// {@macro treatment_form_state}
  TreatmentFormState copyWith({
    TreatmentFormStatus? status,
    String? title,
    String? diagnosis,
    DateTime? startDate,
    DateTime? endDate,
    bool? isTitleValid,
    bool? isDiagnosisValid,
    bool? isStartDateValid,
    bool? isFormValid,
    String? error,
  }) {
    return TreatmentFormState(
      status: status ?? this.status,
      title: title ?? this.title,
      diagnosis: diagnosis ?? this.diagnosis,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isTitleValid: isTitleValid ?? this.isTitleValid,
      isDiagnosisValid: isDiagnosisValid ?? this.isDiagnosisValid,
      isStartDateValid: isStartDateValid ?? this.isStartDateValid,
      isFormValid: isFormValid ?? this.isFormValid,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        title,
        diagnosis,
        startDate,
        endDate,
        isTitleValid,
        isDiagnosisValid,
        isStartDateValid,
        isFormValid,
        error,
      ];
}
