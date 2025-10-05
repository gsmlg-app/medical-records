import 'package:app_database/app_database.dart';
import 'package:equatable/equatable.dart';

abstract class TreatmentState extends Equatable {
  const TreatmentState();

  @override
  List<Object?> get props => [];
}

class TreatmentInitial extends TreatmentState {}

class TreatmentLoading extends TreatmentState {}

class TreatmentLoaded extends TreatmentState {
  final List<Treatment> treatments;

  const TreatmentLoaded(this.treatments);

  @override
  List<Object?> get props => [treatments];
}

class TreatmentError extends TreatmentState {
  final String message;

  const TreatmentError(this.message);

  @override
  List<Object?> get props => [message];
}

class TreatmentOperationSuccess extends TreatmentState {
  final String message;

  const TreatmentOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
