import 'package:app_database/app_database.dart';
import 'package:equatable/equatable.dart';

abstract class DoctorState extends Equatable {
  const DoctorState();

  @override
  List<Object?> get props => [];
}

class DoctorInitial extends DoctorState {
  const DoctorInitial();

  @override
  List<Object?> get props => [];
}

class DoctorLoading extends DoctorState {
  const DoctorLoading();

  @override
  List<Object?> get props => [];
}

class DoctorLoaded extends DoctorState {
  final List<Doctor> doctors;

  const DoctorLoaded(this.doctors);

  @override
  List<Object?> get props => [doctors];
}

class DoctorOperationSuccess extends DoctorState {
  final String message;

  const DoctorOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class DoctorError extends DoctorState {
  final String error;

  const DoctorError(this.error);

  @override
  List<Object?> get props => [error];
}