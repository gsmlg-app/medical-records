part of 'bloc.dart';

/// {@template visit_form_state}
/// VisitFormState represents the state of the visit form.
/// Note: With FormBloc, we primarily use FormBlocState instead of custom states.
/// This class is kept for compatibility and potential future extensions.
/// {@endtemplate}
class VisitFormState extends Equatable {
  /// {@macro visit_form_state}
  const VisitFormState({
    required this.availableHospitals,
    required this.availableDepartments,
    required this.availableDoctors,
  });

  /// Available hospitals for selection
  final List<Hospital> availableHospitals;

  /// Available departments for selection
  final List<Department> availableDepartments;

  /// Available doctors for selection
  final List<Doctor> availableDoctors;

  @override
  List<Object> get props => [
    availableHospitals,
    availableDepartments,
    availableDoctors,
  ];

  @override
  String toString() =>
      'VisitFormState('
      'availableHospitals: ${availableHospitals.length}, '
      'availableDepartments: ${availableDepartments.length}, '
      'availableDoctors: ${availableDoctors.length})';
}
