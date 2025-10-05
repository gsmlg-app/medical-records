import 'package:app_database/app_database.dart';
import 'package:equatable/equatable.dart';

abstract class HospitalState extends Equatable {
  const HospitalState();

  @override
  List<Object?> get props => [];
}

class HospitalInitial extends HospitalState {}

class HospitalLoading extends HospitalState {}

class HospitalLoaded extends HospitalState {
  final List<Hospital> hospitals;

  const HospitalLoaded(this.hospitals);

  @override
  List<Object?> get props => [hospitals];
}

class HospitalError extends HospitalState {
  final String message;

  const HospitalError(this.message);

  @override
  List<Object?> get props => [message];
}

class HospitalOperationSuccess extends HospitalState {
  final String message;

  const HospitalOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}