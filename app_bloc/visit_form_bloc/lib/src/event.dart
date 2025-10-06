import 'package:app_database/app_database.dart';
import 'package:equatable/equatable.dart';

abstract class VisitFormEvent extends Equatable {
  const VisitFormEvent();

  @override
  List<Object?> get props => [];
}

class VisitFormCategoryChanged extends VisitFormEvent {
  final VisitCategory category;

  const VisitFormCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class VisitFormDateChanged extends VisitFormEvent {
  final DateTime date;

  const VisitFormDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class VisitFormDetailsChanged extends VisitFormEvent {
  final String details;

  const VisitFormDetailsChanged(this.details);

  @override
  List<Object?> get props => [details];
}

class VisitFormHospitalIdChanged extends VisitFormEvent {
  final int? hospitalId;

  const VisitFormHospitalIdChanged(this.hospitalId);

  @override
  List<Object?> get props => [hospitalId];
}

class VisitFormDepartmentIdChanged extends VisitFormEvent {
  final int? departmentId;

  const VisitFormDepartmentIdChanged(this.departmentId);

  @override
  List<Object?> get props => [departmentId];
}

class VisitFormDoctorIdChanged extends VisitFormEvent {
  final int? doctorId;

  const VisitFormDoctorIdChanged(this.doctorId);

  @override
  List<Object?> get props => [doctorId];
}

class VisitFormInformationsChanged extends VisitFormEvent {
  final String? informations;

  const VisitFormInformationsChanged(this.informations);

  @override
  List<Object?> get props => [informations];
}

class VisitFormPopulate extends VisitFormEvent {
  final Map<String, dynamic> data;

  const VisitFormPopulate(this.data);

  @override
  List<Object?> get props => [data];
}

class VisitFormReset extends VisitFormEvent {
  const VisitFormReset();
}

// Data loading events
class LoadFormData extends VisitFormEvent {
  const LoadFormData();

  @override
  List<Object?> get props => [];
}

class HospitalsLoaded extends VisitFormEvent {
  final List<Hospital> hospitals;

  const HospitalsLoaded(this.hospitals);

  @override
  List<Object?> get props => [hospitals];
}

class DepartmentsLoaded extends VisitFormEvent {
  final List<Department> departments;

  const DepartmentsLoaded(this.departments);

  @override
  List<Object?> get props => [departments];
}

class DoctorsLoaded extends VisitFormEvent {
  final List<Doctor> doctors;

  const DoctorsLoaded(this.doctors);

  @override
  List<Object?> get props => [doctors];
}

// Cascading selection events
class LoadDepartmentsForHospital extends VisitFormEvent {
  final int? hospitalId;

  const LoadDepartmentsForHospital(this.hospitalId);

  @override
  List<Object?> get props => [hospitalId];
}

class LoadDoctorsForHospitalAndDepartment extends VisitFormEvent {
  final int? hospitalId;
  final int? departmentId;

  const LoadDoctorsForHospitalAndDepartment({
    required this.hospitalId,
    required this.departmentId,
  });

  @override
  List<Object?> get props => [hospitalId, departmentId];
}