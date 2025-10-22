part of 'bloc.dart';

/// Base class for all visit form states
abstract class VisitFormState extends Equatable {
  const VisitFormState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class VisitFormStateInitial extends VisitFormState {
  const VisitFormStateInitial();

  @override
  String toString() => 'VisitFormStateInitial()';
}

/// Loading state
class VisitFormStateLoading extends VisitFormState {
  const VisitFormStateLoading();

  @override
  String toString() => 'VisitFormStateLoading()';
}

/// Ready state with location data loaded
class VisitFormStateReady extends VisitFormState {
  final bool isEditing;
  final Visit? visit;

  const VisitFormStateReady({
    this.isEditing = false,
    this.visit,
  });

  @override
  List<Object?> get props => [isEditing, visit];

  @override
  String toString() => 'VisitFormStateReady(isEditing: $isEditing, visit: $visit)';
}

/// Error state
class VisitFormStateError extends VisitFormState {
  final String message;

  const VisitFormStateError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'VisitFormStateError(message: $message)';
}