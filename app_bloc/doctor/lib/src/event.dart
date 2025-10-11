import 'package:app_database/app_database.dart';
import 'package:equatable/equatable.dart';

abstract class DoctorEvent extends Equatable {
  const DoctorEvent();

  @override
  List<Object?> get props => [];
}

class LoadDoctors extends DoctorEvent {
  const LoadDoctors();

  @override
  List<Object?> get props => [];
}

class LoadDoctorsByHospital extends DoctorEvent {
  final int hospitalId;

  const LoadDoctorsByHospital(this.hospitalId);

  @override
  List<Object?> get props => [hospitalId];
}

class LoadDoctorsByDepartment extends DoctorEvent {
  final int departmentId;

  const LoadDoctorsByDepartment(this.departmentId);

  @override
  List<Object?> get props => [departmentId];
}

class LoadDoctorsByHospitalAndDepartment extends DoctorEvent {
  final int hospitalId;
  final int departmentId;

  const LoadDoctorsByHospitalAndDepartment({
    required this.hospitalId,
    required this.departmentId,
  });

  @override
  List<Object?> get props => [hospitalId, departmentId];
}

class AddDoctor extends DoctorEvent {
  final String name;
  final int hospitalId;
  final int departmentId;
  final String? level;

  const AddDoctor({
    required this.name,
    required this.hospitalId,
    required this.departmentId,
    this.level,
  });

  @override
  List<Object?> get props => [name, hospitalId, departmentId, level];
}

class UpdateDoctor extends DoctorEvent {
  final Doctor doctor;

  const UpdateDoctor(this.doctor);

  @override
  List<Object?> get props => [doctor];
}

class DeleteDoctor extends DoctorEvent {
  final int doctorId;

  const DeleteDoctor(this.doctorId);

  @override
  List<Object?> get props => [doctorId];
}
