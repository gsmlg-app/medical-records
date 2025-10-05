import 'package:equatable/equatable.dart';

abstract class TreatmentEvent extends Equatable {
  const TreatmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadTreatments extends TreatmentEvent {}

class AddTreatment extends TreatmentEvent {
  final String title;
  final String diagnosis;
  final DateTime startDate;
  final DateTime? endDate;

  const AddTreatment({
    required this.title,
    required this.diagnosis,
    required this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [title, diagnosis, startDate, endDate];
}

class UpdateTreatment extends TreatmentEvent {
  final int id;
  final String title;
  final String diagnosis;
  final DateTime startDate;
  final DateTime? endDate;

  const UpdateTreatment({
    required this.id,
    required this.title,
    required this.diagnosis,
    required this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [id, title, diagnosis, startDate, endDate];
}

class DeleteTreatment extends TreatmentEvent {
  final int id;

  const DeleteTreatment(this.id);

  @override
  List<Object?> get props => [id];
}
