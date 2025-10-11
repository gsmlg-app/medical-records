import 'package:equatable/equatable.dart';

abstract class HospitalFormEvent extends Equatable {
  const HospitalFormEvent();

  @override
  List<Object?> get props => [];
}

class InitializeForm extends HospitalFormEvent {
  final String? name;
  final String? address;
  final String? type;
  final String? level;

  const InitializeForm({this.name, this.address, this.type, this.level});

  @override
  List<Object?> get props => [name, address, type, level];
}

class NameChanged extends HospitalFormEvent {
  final String name;

  const NameChanged(this.name);

  @override
  List<Object?> get props => [name];
}

class AddressChanged extends HospitalFormEvent {
  final String address;

  const AddressChanged(this.address);

  @override
  List<Object?> get props => [address];
}

class TypeChanged extends HospitalFormEvent {
  final String type;

  const TypeChanged(this.type);

  @override
  List<Object?> get props => [type];
}

class LevelChanged extends HospitalFormEvent {
  final String level;

  const LevelChanged(this.level);

  @override
  List<Object?> get props => [level];
}

class FormSubmitted extends HospitalFormEvent {
  const FormSubmitted();
}

class FormReset extends HospitalFormEvent {
  const FormReset();
}

class HospitalFormSuccess extends HospitalFormEvent {
  const HospitalFormSuccess();
}

class HospitalFormFailure extends HospitalFormEvent {
  final String error;

  const HospitalFormFailure(this.error);

  @override
  List<Object?> get props => [error];
}
