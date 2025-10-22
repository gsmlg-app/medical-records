import 'package:app_database/app_database.dart';
import 'package:equatable/equatable.dart';

/// Base class for all visit resource states
abstract class VisitResourceState extends Equatable {
  const VisitResourceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class VisitResourceStateInitial extends VisitResourceState {
  const VisitResourceStateInitial();

  @override
  String toString() => 'VisitResourceStateInitial()';
}

/// Loading state
class VisitResourceStateLoading extends VisitResourceState {
  const VisitResourceStateLoading();

  @override
  String toString() => 'VisitResourceStateLoading()';
}

/// Loaded state with resources
class VisitResourceStateLoaded extends VisitResourceState {
  final List<Resource> resources;

  const VisitResourceStateLoaded(this.resources);

  VisitResourceStateLoaded copyWith({List<Resource>? resources}) {
    return VisitResourceStateLoaded(resources ?? this.resources);
  }

  @override
  List<Object?> get props => [resources];

  @override
  String toString() =>
      'VisitResourceStateLoaded(resources: ${resources.length})';
}

/// Error state
class VisitResourceStateError extends VisitResourceState {
  final String message;

  const VisitResourceStateError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'VisitResourceStateError(message: $message)';
}
