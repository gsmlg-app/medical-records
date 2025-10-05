import 'package:app_database/app_database.dart';
import 'package:equatable/equatable.dart';

abstract class VisitState extends Equatable {
  const VisitState();

  @override
  List<Object?> get props => [];
}

class VisitInitial extends VisitState {}

class VisitLoading extends VisitState {}

class VisitLoaded extends VisitState {
  final List<Visit> visits;

  const VisitLoaded(this.visits);

  @override
  List<Object?> get props => [visits];
}

class VisitError extends VisitState {
  final String message;

  const VisitError(this.message);

  @override
  List<Object?> get props => [message];
}

class VisitOperationSuccess extends VisitState {
  final String message;

  const VisitOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
