import 'package:equatable/equatable.dart';

abstract class HospitalFormState extends Equatable {
  const HospitalFormState();

  @override
  List<Object?> get props => [];
}

class HospitalFormInitial extends HospitalFormState {}

class HospitalFormLoadInProgress extends HospitalFormState {}

class HospitalFormLoaded extends HospitalFormState {
  final String name;
  final String address;
  final String type;
  final String level;
  final bool isNameValid;
  final bool isSubmitting;

  const HospitalFormLoaded({
    required this.name,
    required this.address,
    required this.type,
    required this.level,
    required this.isNameValid,
    this.isSubmitting = false,
  });

  HospitalFormLoaded copyWith({
    String? name,
    String? address,
    String? type,
    String? level,
    bool? isNameValid,
    bool? isSubmitting,
  }) {
    return HospitalFormLoaded(
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      level: level ?? this.level,
      isNameValid: isNameValid ?? this.isNameValid,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        name,
        address,
        type,
        level,
        isNameValid,
        isSubmitting,
      ];
}

class HospitalFormSubmissionInProgress extends HospitalFormState {
  final String name;
  final String address;
  final String type;
  final String level;

  const HospitalFormSubmissionInProgress({
    required this.name,
    required this.address,
    required this.type,
    required this.level,
  });

  @override
  List<Object?> get props => [name, address, type, level];
}

class HospitalFormSubmissionSuccess extends HospitalFormState {
  final String message;

  const HospitalFormSubmissionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class HospitalFormSubmissionFailure extends HospitalFormState {
  final String error;
  final String name;
  final String address;
  final String type;
  final String level;

  const HospitalFormSubmissionFailure({
    required this.error,
    required this.name,
    required this.address,
    required this.type,
    required this.level,
  });

  @override
  List<Object?> get props => [error, name, address, type, level];
}