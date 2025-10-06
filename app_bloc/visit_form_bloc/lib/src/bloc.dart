import 'package:app_database/app_database.dart';
import 'package:bloc/bloc.dart';

import 'event.dart';
import 'state.dart';

class VisitFormBloc extends Bloc<VisitFormEvent, VisitFormState> {
  final AppDatabase _database;

  VisitFormBloc(this._database) : super(VisitFormState.initial()) {
    on<VisitFormCategoryChanged>(_onCategoryChanged);
    on<VisitFormDateChanged>(_onDateChanged);
    on<VisitFormDetailsChanged>(_onDetailsChanged);
    on<VisitFormHospitalIdChanged>(_onHospitalIdChanged);
    on<VisitFormDepartmentIdChanged>(_onDepartmentIdChanged);
    on<VisitFormDoctorIdChanged>(_onDoctorIdChanged);
    on<VisitFormInformationsChanged>(_onInformationsChanged);
    on<VisitFormPopulate>(_onPopulate);
    on<VisitFormReset>(_onReset);

    // New data loading events
    on<LoadFormData>(_onLoadFormData);
    on<HospitalsLoaded>(_onHospitalsLoaded);
    on<DepartmentsLoaded>(_onDepartmentsLoaded);
    on<DoctorsLoaded>(_onDoctorsLoaded);

    // Cascading selection events
    on<LoadDepartmentsForHospital>(_onLoadDepartmentsForHospital);
    on<LoadDoctorsForHospitalAndDepartment>(_onLoadDoctorsForHospitalAndDepartment);
  }

  void _onCategoryChanged(
    VisitFormCategoryChanged event,
    Emitter<VisitFormState> emit,
  ) {
    emit(state.copyWith(category: event.category));
    _validateForm(emit);
  }

  void _onDateChanged(
    VisitFormDateChanged event,
    Emitter<VisitFormState> emit,
  ) {
    emit(state.copyWith(date: event.date));
    _validateForm(emit);
  }

  void _onDetailsChanged(
    VisitFormDetailsChanged event,
    Emitter<VisitFormState> emit,
  ) {
    emit(state.copyWith(details: event.details));
    _validateForm(emit);
  }

  void _onHospitalIdChanged(
    VisitFormHospitalIdChanged event,
    Emitter<VisitFormState> emit,
  ) {
    emit(state.copyWith(
      hospitalId: event.hospitalId,
      departmentId: null, // Reset department when hospital changes
      doctorId: null, // Reset doctor when hospital changes
    ));

    // Trigger cascading data loading
    add(LoadDepartmentsForHospital(event.hospitalId));
    if (event.hospitalId != null) {
      add(LoadDoctorsForHospitalAndDepartment(
        hospitalId: event.hospitalId!,
        departmentId: state.departmentId,
      ));
    }

    _validateForm(emit);
  }

  void _onDepartmentIdChanged(
    VisitFormDepartmentIdChanged event,
    Emitter<VisitFormState> emit,
  ) {
    emit(state.copyWith(
      departmentId: event.departmentId,
      doctorId: null, // Reset doctor when department changes
    ));

    // Trigger cascading data loading for doctors
    add(LoadDoctorsForHospitalAndDepartment(
      hospitalId: state.hospitalId,
      departmentId: event.departmentId,
    ));

    _validateForm(emit);
  }

  void _onDoctorIdChanged(
    VisitFormDoctorIdChanged event,
    Emitter<VisitFormState> emit,
  ) {
    emit(state.copyWith(doctorId: event.doctorId));
    _validateForm(emit);
  }

  void _onInformationsChanged(
    VisitFormInformationsChanged event,
    Emitter<VisitFormState> emit,
  ) {
    emit(state.copyWith(informations: event.informations));
    _validateForm(emit);
  }

  void _onPopulate(
    VisitFormPopulate event,
    Emitter<VisitFormState> emit,
  ) {
    final data = event.data;
    emit(state.copyWith(
      category: data['category'] as VisitCategory? ?? VisitCategory.outpatient,
      date: data['date'] as DateTime?,
      details: data['details'] as String? ?? '',
      hospitalId: data['hospitalId'] as int?,
      departmentId: data['departmentId'] as int?,
      doctorId: data['doctorId'] as int?,
      informations: data['informations'] as String?,
    ));
    _validateForm(emit);
  }

  void _onReset(
    VisitFormReset event,
    Emitter<VisitFormState> emit,
  ) {
    emit(VisitFormState.initial());
  }

  // New data loading event handlers
  Future<void> _onLoadFormData(
    LoadFormData event,
    Emitter<VisitFormState> emit,
  ) async {
    emit(state.copyWith(
      isLoadingHospitals: true,
      isLoadingDepartments: true,
      isLoadingDoctors: true,
    ));

    try {
      // Load all data in parallel
      final hospitalsFuture = _database.getAllHospitals();
      final departmentsFuture = _database.getAllDepartments();
      final doctorsFuture = _database.getAllDoctors();

      final results = await Future.wait([
        hospitalsFuture,
        departmentsFuture,
        doctorsFuture,
      ]);

      emit(state.copyWith(
        availableHospitals: results[0] as List<Hospital>,
        availableDepartments: results[1] as List<Department>,
        availableDoctors: results[2] as List<Doctor>,
        isLoadingHospitals: false,
        isLoadingDepartments: false,
        isLoadingDoctors: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to load form data: ${e.toString()}',
        isLoadingHospitals: false,
        isLoadingDepartments: false,
        isLoadingDoctors: false,
      ));
    }
  }

  void _onHospitalsLoaded(
    HospitalsLoaded event,
    Emitter<VisitFormState> emit,
  ) {
    emit(state.copyWith(
      availableHospitals: event.hospitals,
      isLoadingHospitals: false,
    ));
  }

  void _onDepartmentsLoaded(
    DepartmentsLoaded event,
    Emitter<VisitFormState> emit,
  ) {
    emit(state.copyWith(
      availableDepartments: event.departments,
      isLoadingDepartments: false,
    ));
  }

  void _onDoctorsLoaded(
    DoctorsLoaded event,
    Emitter<VisitFormState> emit,
  ) {
    emit(state.copyWith(
      availableDoctors: event.doctors,
      isLoadingDoctors: false,
    ));
  }

  // Cascading selection event handlers
  Future<void> _onLoadDepartmentsForHospital(
    LoadDepartmentsForHospital event,
    Emitter<VisitFormState> emit,
  ) async {
    emit(state.copyWith(isLoadingDepartments: true));

    try {
      final allDepartments = await _database.getAllDepartments();
      emit(state.copyWith(
        availableDepartments: allDepartments,
        isLoadingDepartments: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to load departments: ${e.toString()}',
        isLoadingDepartments: false,
      ));
    }
  }

  Future<void> _onLoadDoctorsForHospitalAndDepartment(
    LoadDoctorsForHospitalAndDepartment event,
    Emitter<VisitFormState> emit,
  ) async {
    emit(state.copyWith(isLoadingDoctors: true));

    try {
      final allDoctors = await _database.getAllDoctors();
      List<Doctor> filteredDoctors = allDoctors;

      // Filter by hospital if specified
      if (event.hospitalId != null) {
        filteredDoctors = filteredDoctors
            .where((doctor) => doctor.hospitalId == event.hospitalId)
            .toList();
      }

      // Filter by department if specified
      if (event.departmentId != null) {
        filteredDoctors = filteredDoctors
            .where((doctor) => doctor.departmentId == event.departmentId)
            .toList();
      }

      emit(state.copyWith(
        availableDoctors: filteredDoctors,
        isLoadingDoctors: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to load doctors: ${e.toString()}',
        isLoadingDoctors: false,
      ));
    }
  }

  void _validateForm(Emitter<VisitFormState> emit) {
    if (state.isFormValid) {
      emit(state.copyWith(status: VisitFormStatus.valid, error: null));
    } else {
      emit(state.copyWith(status: VisitFormStatus.invalid, error: null));
    }
  }
}