import 'package:equatable/equatable.dart';

/// Base class for all visit location events
abstract class VisitLocationEvent extends Equatable {
  const VisitLocationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all location data
class LoadHospitals extends VisitLocationEvent {
  const LoadHospitals();

  @override
  String toString() => 'LoadHospitals()';
}

/// Event to refresh hospitals list
class RefreshHospitals extends VisitLocationEvent {
  final bool selectNewest;

  const RefreshHospitals({this.selectNewest = false});

  @override
  List<Object?> get props => [selectNewest];

  @override
  String toString() => 'RefreshHospitals(selectNewest: $selectNewest)';
}

/// Event to quickly add a new department
class QuickAddDepartment extends VisitLocationEvent {
  final String name;
  final String? category;

  const QuickAddDepartment(this.name, {this.category});

  @override
  List<Object?> get props => [name, category];

  @override
  String toString() => 'QuickAddDepartment(name: $name, category: $category)';
}

/// Event to quickly add a new doctor
class QuickAddDoctor extends VisitLocationEvent {
  final String name;
  final String? title;
  final String? specialty;

  const QuickAddDoctor(this.name, {this.title, this.specialty});

  @override
  List<Object?> get props => [name, title, specialty];

  @override
  String toString() =>
      'QuickAddDoctor(name: $name, title: $title, specialty: $specialty)';
}

/// Event to update department options
class UpdateDepartmentOptions extends VisitLocationEvent {
  const UpdateDepartmentOptions();

  @override
  String toString() => 'UpdateDepartmentOptions()';
}

/// Event to update doctor options
class UpdateDoctorOptions extends VisitLocationEvent {
  const UpdateDoctorOptions();

  @override
  String toString() => 'UpdateDoctorOptions()';
}

/// Event when hospital selection changes
class HospitalChanged extends VisitLocationEvent {
  final int? hospitalId;

  const HospitalChanged(this.hospitalId);

  @override
  List<Object?> get props => [hospitalId];

  @override
  String toString() => 'HospitalChanged(hospitalId: $hospitalId)';
}

/// Event when department selection changes
class DepartmentChanged extends VisitLocationEvent {
  final int? departmentId;

  const DepartmentChanged(this.departmentId);

  @override
  List<Object?> get props => [departmentId];

  @override
  String toString() => 'DepartmentChanged(departmentId: $departmentId)';
}
