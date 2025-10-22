import 'package:app_database/app_database.dart';
import 'package:equatable/equatable.dart';

/// Base class for all visit location states
abstract class VisitLocationState extends Equatable {
  const VisitLocationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class VisitLocationStateInitial extends VisitLocationState {
  const VisitLocationStateInitial();

  @override
  String toString() => 'VisitLocationStateInitial()';
}

/// Loading state
class VisitLocationStateLoading extends VisitLocationState {
  const VisitLocationStateLoading();

  @override
  String toString() => 'VisitLocationStateLoading()';
}

/// Loaded state with location data
class VisitLocationStateLoaded extends VisitLocationState {
  final List<Hospital> hospitals;
  final List<Department> departments;
  final List<Doctor> doctors;
  final int? selectedHospitalId;
  final int? selectedDepartmentId;
  final int? selectedDoctorId;
  final Hospital? newestHospital;
  final int? newDepartmentId;
  final int? newDoctorId;

  const VisitLocationStateLoaded({
    required this.hospitals,
    required this.departments,
    required this.doctors,
    this.selectedHospitalId,
    this.selectedDepartmentId,
    this.selectedDoctorId,
    this.newestHospital,
    this.newDepartmentId,
    this.newDoctorId,
  });

  VisitLocationStateLoaded copyWith({
    List<Hospital>? hospitals,
    List<Department>? departments,
    List<Doctor>? doctors,
    int? selectedHospitalId,
    int? selectedDepartmentId,
    int? selectedDoctorId,
    Hospital? newestHospital,
    int? newDepartmentId,
    int? newDoctorId,
  }) {
    return VisitLocationStateLoaded(
      hospitals: hospitals ?? this.hospitals,
      departments: departments ?? this.departments,
      doctors: doctors ?? this.doctors,
      selectedHospitalId: selectedHospitalId ?? this.selectedHospitalId,
      selectedDepartmentId: selectedDepartmentId ?? this.selectedDepartmentId,
      selectedDoctorId: selectedDoctorId ?? this.selectedDoctorId,
      newestHospital: newestHospital ?? this.newestHospital,
      newDepartmentId: newDepartmentId,
      newDoctorId: newDoctorId,
    );
  }

  @override
  List<Object?> get props => [
    hospitals,
    departments,
    doctors,
    selectedHospitalId,
    selectedDepartmentId,
    selectedDoctorId,
    newestHospital,
    newDepartmentId,
    newDoctorId,
  ];

  @override
  String toString() =>
      'VisitLocationStateLoaded('
      'hospitals: ${hospitals.length}, '
      'departments: ${departments.length}, '
      'doctors: ${doctors.length}, '
      'selectedHospitalId: $selectedHospitalId, '
      'selectedDepartmentId: $selectedDepartmentId, '
      'selectedDoctorId: $selectedDoctorId, '
      'newestHospital: $newestHospital, '
      'newDepartmentId: $newDepartmentId, '
      'newDoctorId: $newDoctorId)';
}

/// Error state
class VisitLocationStateError extends VisitLocationState {
  final String message;

  const VisitLocationStateError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'VisitLocationStateError(message: $message)';
}
