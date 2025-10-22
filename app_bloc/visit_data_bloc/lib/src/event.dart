part of 'bloc.dart';

/// Base class for all visit data events
abstract class VisitDataEvent extends Equatable {
  const VisitDataEvent();

  @override
  List<Object?> get props => [];
}

/// Event to create a new visit
class CreateVisit extends VisitDataEvent {
  final int treatmentId;
  final VisitCategory category;
  final DateTime date;
  final String details;
  final int? hospitalId;
  final int? departmentId;
  final int? doctorId;

  const CreateVisit({
    required this.treatmentId,
    required this.category,
    required this.date,
    required this.details,
    this.hospitalId,
    this.departmentId,
    this.doctorId,
  });

  @override
  List<Object?> get props => [
    treatmentId,
    category,
    date,
    details,
    hospitalId,
    departmentId,
    doctorId,
  ];

  @override
  String toString() =>
      'CreateVisit('
      'treatmentId: $treatmentId, '
      'category: $category, '
      'date: $date, '
      'details: $details, '
      'hospitalId: $hospitalId, '
      'departmentId: $departmentId, '
      'doctorId: $doctorId)';
}

/// Event to update an existing visit
class UpdateVisitData extends VisitDataEvent {
  final int visitId;
  final int treatmentId;
  final VisitCategory category;
  final DateTime date;
  final String details;
  final int? hospitalId;
  final int? departmentId;
  final int? doctorId;

  const UpdateVisitData({
    required this.visitId,
    required this.treatmentId,
    required this.category,
    required this.date,
    required this.details,
    this.hospitalId,
    this.departmentId,
    this.doctorId,
  });

  @override
  List<Object?> get props => [
    visitId,
    treatmentId,
    category,
    date,
    details,
    hospitalId,
    departmentId,
    doctorId,
  ];

  @override
  String toString() =>
      'UpdateVisitData('
      'visitId: $visitId, '
      'treatmentId: $treatmentId, '
      'category: $category, '
      'date: $date, '
      'details: $details, '
      'hospitalId: $hospitalId, '
      'departmentId: $departmentId, '
      'doctorId: $doctorId)';
}

/// Event to delete a visit
class DeleteVisit extends VisitDataEvent {
  final int visitId;

  const DeleteVisit(this.visitId);

  @override
  List<Object?> get props => [visitId];

  @override
  String toString() => 'DeleteVisit(visitId: $visitId)';
}

/// Event to load a specific visit
class LoadVisit extends VisitDataEvent {
  final int visitId;

  const LoadVisit(this.visitId);

  @override
  List<Object?> get props => [visitId];

  @override
  String toString() => 'LoadVisit(visitId: $visitId)';
}
