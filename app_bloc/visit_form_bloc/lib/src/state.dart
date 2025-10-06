import 'package:app_database/app_database.dart';
import 'package:equatable/equatable.dart';

enum VisitFormStatus {
  initial,
  loading,
  valid,
  invalid,
}

class VisitFormState extends Equatable {
  final VisitCategory category;
  final DateTime? date;
  final String details;
  final int? hospitalId;
  final int? departmentId;
  final int? doctorId;
  final String? informations;
  final VisitFormStatus status;
  final String? error;

  // Available data for dropdowns
  final List<Hospital> availableHospitals;
  final List<Department> availableDepartments;
  final List<Doctor> availableDoctors;
  final bool isLoadingHospitals;
  final bool isLoadingDepartments;
  final bool isLoadingDoctors;

  const VisitFormState({
    this.category = VisitCategory.outpatient,
    this.date,
    this.details = '',
    this.hospitalId,
    this.departmentId,
    this.doctorId,
    this.informations,
    this.status = VisitFormStatus.initial,
    this.error,
    this.availableHospitals = const [],
    this.availableDepartments = const [],
    this.availableDoctors = const [],
    this.isLoadingHospitals = false,
    this.isLoadingDepartments = false,
    this.isLoadingDoctors = false,
  });

  factory VisitFormState.initial() {
    return const VisitFormState();
  }

  VisitFormState copyWith({
    VisitCategory? category,
    DateTime? date,
    String? details,
    int? hospitalId,
    int? departmentId,
    int? doctorId,
    String? informations,
    VisitFormStatus? status,
    String? error,
    List<Hospital>? availableHospitals,
    List<Department>? availableDepartments,
    List<Doctor>? availableDoctors,
    bool? isLoadingHospitals,
    bool? isLoadingDepartments,
    bool? isLoadingDoctors,
  }) {
    return VisitFormState(
      category: category ?? this.category,
      date: date ?? this.date,
      details: details ?? this.details,
      hospitalId: hospitalId ?? this.hospitalId,
      departmentId: departmentId ?? this.departmentId,
      doctorId: doctorId ?? this.doctorId,
      informations: informations ?? this.informations,
      status: status ?? this.status,
      error: error ?? this.error,
      availableHospitals: availableHospitals ?? this.availableHospitals,
      availableDepartments: availableDepartments ?? this.availableDepartments,
      availableDoctors: availableDoctors ?? this.availableDoctors,
      isLoadingHospitals: isLoadingHospitals ?? this.isLoadingHospitals,
      isLoadingDepartments: isLoadingDepartments ?? this.isLoadingDepartments,
      isLoadingDoctors: isLoadingDoctors ?? this.isLoadingDoctors,
    );
  }

  @override
  List<Object?> get props => [
        category,
        date,
        details,
        hospitalId,
        departmentId,
        doctorId,
        informations,
        status,
        error,
        availableHospitals,
        availableDepartments,
        availableDoctors,
        isLoadingHospitals,
        isLoadingDepartments,
        isLoadingDoctors,
      ];

  bool get isCategoryValid => category != VisitCategory.outpatient || true; // Category is always valid
  bool get isDateValid => date != null;
  bool get isDetailsValid => details.trim().isNotEmpty;

  bool get isFormValid => isCategoryValid && isDateValid && isDetailsValid;
}