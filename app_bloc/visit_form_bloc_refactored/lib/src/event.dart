part of 'bloc.dart';

/// Base class for all visit form events
abstract class VisitFormEvent extends Equatable {
  const VisitFormEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load existing visit data
class LoadVisitData extends VisitFormEvent {
  final Visit visit;

  const LoadVisitData(this.visit);

  @override
  List<Object?> get props => [visit];

  @override
  String toString() => 'LoadVisitData(visit: $visit)';
}

/// Event to refresh location data
class RefreshLocationData extends VisitFormEvent {
  final bool selectNewest;

  const RefreshLocationData({this.selectNewest = false});

  @override
  List<Object?> get props => [selectNewest];

  @override
  String toString() => 'RefreshLocationData(selectNewest: $selectNewest)';
}