import 'package:equatable/equatable.dart';

abstract class HospitalEvent extends Equatable {
  const HospitalEvent();

  @override
  List<Object?> get props => [];
}

class LoadHospitals extends HospitalEvent {}

class AddHospital extends HospitalEvent {
  final String name;
  final String? address;
  final String? type;
  final String? level;

  const AddHospital({
    required this.name,
    this.address,
    this.type,
    this.level,
  });

  @override
  List<Object?> get props => [name, address, type, level];
}

class UpdateHospital extends HospitalEvent {
  final int id;
  final String name;
  final String? address;
  final String? type;
  final String? level;

  const UpdateHospital({
    required this.id,
    required this.name,
    this.address,
    this.type,
    this.level,
  });

  @override
  List<Object?> get props => [id, name, address, type, level];
}

class DeleteHospital extends HospitalEvent {
  final int id;

  const DeleteHospital(this.id);

  @override
  List<Object?> get props => [id];
}