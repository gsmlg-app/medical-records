part of 'bloc.dart';

/// Base class for all visit data states
abstract class VisitDataState extends Equatable {
  const VisitDataState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class VisitDataStateInitial extends VisitDataState {
  const VisitDataStateInitial();

  @override
  String toString() => 'VisitDataStateInitial()';
}

/// Loading state
class VisitDataStateLoading extends VisitDataState {
  const VisitDataStateLoading();

  @override
  String toString() => 'VisitDataStateLoading()';
}

/// Success state with optional visit data
class VisitDataStateSuccess extends VisitDataState {
  final Visit? visit;
  final String message;

  const VisitDataStateSuccess(this.visit, this.message);

  @override
  List<Object?> get props => [visit, message];

  @override
  String toString() =>
      'VisitDataStateSuccess(visit: $visit, message: $message)';
}

/// Error state
class VisitDataStateError extends VisitDataState {
  final String message;

  const VisitDataStateError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'VisitDataStateError(message: $message)';
}
