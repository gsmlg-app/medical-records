import 'package:app_database/app_database.dart';
import 'package:equatable/equatable.dart';

abstract class VisitEvent extends Equatable {
  const VisitEvent();

  @override
  List<Object?> get props => [];
}

class LoadVisits extends VisitEvent {}

class LoadVisitsByTreatment extends VisitEvent {
  final int treatmentId;

  const LoadVisitsByTreatment(this.treatmentId);

  @override
  List<Object?> get props => [treatmentId];
}

class AddVisit extends VisitEvent {
  final int treatmentId;
  final VisitCategory category;
  final DateTime date;
  final String details;
  final int? hospitalId;
  final int? departmentId;
  final int? doctorId;
  final String? informations;

  const AddVisit({
    required this.treatmentId,
    required this.category,
    required this.date,
    required this.details,
    this.hospitalId,
    this.departmentId,
    this.doctorId,
    this.informations,
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
        informations,
      ];
}

class UpdateVisit extends VisitEvent {
  final int id;
  final int treatmentId;
  final VisitCategory category;
  final DateTime date;
  final String details;
  final int? hospitalId;
  final int? departmentId;
  final int? doctorId;
  final String? informations;

  const UpdateVisit({
    required this.id,
    required this.treatmentId,
    required this.category,
    required this.date,
    required this.details,
    this.hospitalId,
    this.departmentId,
    this.doctorId,
    this.informations,
  });

  @override
  List<Object?> get props => [
        id,
        treatmentId,
        category,
        date,
        details,
        hospitalId,
        departmentId,
        doctorId,
        informations,
      ];
}

class DeleteVisit extends VisitEvent {
  final int id;

  const DeleteVisit(this.id);

  @override
  List<Object?> get props => [id];
}
