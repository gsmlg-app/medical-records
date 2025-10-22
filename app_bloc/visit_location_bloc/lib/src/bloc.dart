import 'dart:async';

import 'package:app_database/app_database.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_utils/app_utils.dart';
import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';

import 'event.dart';
import 'state.dart';

/// {@template visit_location_bloc}
/// BLoC for managing hospital, department, and doctor relationships.
/// {@endtemplate}
class VisitLocationBloc extends Bloc<VisitLocationEvent, VisitLocationState> {
  /// {@macro visit_location_bloc}
  final AppDatabase _database;
  final _fieldHelper = FieldDependencyHelper();

  /// Available hospitals for selection
  List<Hospital> availableHospitals = [];

  /// Available departments for selection
  List<Department> availableDepartments = [];

  /// Available doctors for selection
  List<Doctor> availableDoctors = [];

  /// All doctors loaded from database
  List<Doctor> allDoctors = [];

  /// {@macro visit_location_bloc}
  VisitLocationBloc(this._database) : super(const VisitLocationStateInitial()) {
    on<LoadHospitals>(_onLoadHospitals);
    on<RefreshHospitals>(_onRefreshHospitals);
    on<QuickAddDepartment>(_onQuickAddDepartment);
    on<QuickAddDoctor>(_onQuickAddDoctor);
    on<UpdateDepartmentOptions>(_onUpdateDepartmentOptions);
    on<UpdateDoctorOptions>(_onUpdateDoctorOptions);
    on<HospitalChanged>(_onHospitalChanged);
    on<DepartmentChanged>(_onDepartmentChanged);
  }

  Future<void> _onLoadHospitals(
    LoadHospitals event,
    Emitter<VisitLocationState> emit,
  ) async {
    try {
      emit(const VisitLocationStateLoading());

      availableHospitals = await _database.getAllHospitals();
      availableDepartments = await _database.getAllDepartments();
      allDoctors = await _database.getAllDoctors();
      availableDoctors = allDoctors;

      emit(
        VisitLocationStateLoaded(
          hospitals: availableHospitals,
          departments: availableDepartments,
          doctors: availableDoctors,
        ),
      );
    } catch (e) {
      AppLogger().e('Failed to load location data: $e');
      emit(VisitLocationStateError(e.toString()));
    }
  }

  Future<void> _onRefreshHospitals(
    RefreshHospitals event,
    Emitter<VisitLocationState> emit,
  ) async {
    try {
      AppLogger().d(
        'Refreshing hospitals list, selectNewest: ${event.selectNewest}',
      );
      emit(const VisitLocationStateLoading());

      final previousCount = availableHospitals.length;
      availableHospitals = await _database.getAllHospitals();
      allDoctors = await _database.getAllDoctors();
      availableDoctors = allDoctors;

      Hospital? newestHospital;
      int? selectedHospitalId;

      if (event.selectNewest && availableHospitals.length > previousCount) {
        newestHospital = availableHospitals.reduce(
          (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
        );
        selectedHospitalId = newestHospital.id;
        AppLogger().d('Selecting newly added hospital: ${newestHospital.name}');
      }

      emit(
        VisitLocationStateLoaded(
          hospitals: availableHospitals,
          departments: availableDepartments,
          doctors: availableDoctors,
          selectedHospitalId: selectedHospitalId,
          newestHospital: newestHospital,
        ),
      );

      if (event.selectNewest) {
        _updateDepartmentOptions();
      }
    } catch (e) {
      AppLogger().e('Failed to refresh hospitals: $e');
      emit(VisitLocationStateError(e.toString()));
    }
  }

  Future<void> _onQuickAddDepartment(
    QuickAddDepartment event,
    Emitter<VisitLocationState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! VisitLocationStateLoaded) {
        emit(const VisitLocationStateError('Location data not loaded'));
        return;
      }

      final hospitalId = currentState.selectedHospitalId;
      if (hospitalId == null) {
        emit(const VisitLocationStateError('No hospital selected'));
        return;
      }

      final departmentId = await _database.createDepartment(
        DepartmentsCompanion(
          name: Value(event.name),
          category: Value(event.category),
        ),
      );

      AppLogger().d('Created new department with ID: $departmentId');

      // Update hospital with new department
      final hospital = await _database.getHospital(hospitalId);
      if (hospital != null) {
        List<int> departmentIds;
        try {
          departmentIds = List<int>.from(
            hospital.departmentIds.split(',').map(int.parse),
          );
        } catch (e) {
          AppLogger().e('Error parsing existing departmentIds: $e');
          departmentIds = [];
        }

        if (!departmentIds.contains(departmentId)) {
          departmentIds.add(departmentId);
          await _database.updateHospital(
            hospital.copyWith(departmentIds: departmentIds.join(',')),
          );
          AppLogger().d('Updated hospital with new department ID');
        }
      }

      _updateDepartmentOptions();

      // Emit success with the new department ID
      emit(currentState.copyWith(newDepartmentId: departmentId));
    } catch (e) {
      AppLogger().e('Failed to add department: $e');
      emit(VisitLocationStateError(e.toString()));
    }
  }

  Future<void> _onQuickAddDoctor(
    QuickAddDoctor event,
    Emitter<VisitLocationState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! VisitLocationStateLoaded) {
        emit(const VisitLocationStateError('Location data not loaded'));
        return;
      }

      final hospitalId = currentState.selectedHospitalId;
      final departmentId = currentState.selectedDepartmentId;

      if (hospitalId == null) {
        emit(const VisitLocationStateError('No hospital selected'));
        return;
      }

      if (departmentId == null) {
        emit(const VisitLocationStateError('No department selected'));
        return;
      }

      final doctorLevel = _calculateDoctorLevel(event.title, event.specialty);

      final doctorId = await _database.createDoctor(
        DoctorsCompanion(
          name: Value(event.name),
          hospitalId: Value(hospitalId),
          departmentId: Value(departmentId),
          level: Value(doctorLevel),
        ),
      );

      AppLogger().d('Created new doctor with ID: $doctorId');

      _updateDoctorOptions();

      // Emit success with the new doctor ID
      emit(currentState.copyWith(newDoctorId: doctorId));
    } catch (e) {
      AppLogger().e('Failed to add doctor: $e');
      emit(VisitLocationStateError(e.toString()));
    }
  }

  Future<void> _onUpdateDepartmentOptions(
    UpdateDepartmentOptions event,
    Emitter<VisitLocationState> emit,
  ) async {
    await _updateDepartmentOptions();
  }

  Future<void> _onUpdateDoctorOptions(
    UpdateDoctorOptions event,
    Emitter<VisitLocationState> emit,
  ) async {
    _updateDoctorOptions();
  }

  Future<void> _onHospitalChanged(
    HospitalChanged event,
    Emitter<VisitLocationState> emit,
  ) async {
    final currentState = state;
    if (currentState is VisitLocationStateLoaded) {
      AppLogger().d('Hospital changed to: ${event.hospitalId}');

      emit(
        VisitLocationStateLoaded(
          hospitals: currentState.hospitals,
          departments: currentState.departments,
          doctors: currentState.doctors,
          selectedHospitalId: event.hospitalId,
          selectedDepartmentId: null, // Clear department when hospital changes
          selectedDoctorId: null, // Clear doctor when hospital changes
          newestHospital: currentState.newestHospital,
          newDepartmentId: currentState.newDepartmentId,
          newDoctorId: currentState.newDoctorId,
        ),
      );
    }
  }

  Future<void> _onDepartmentChanged(
    DepartmentChanged event,
    Emitter<VisitLocationState> emit,
  ) async {
    final currentState = state;
    if (currentState is VisitLocationStateLoaded) {
      AppLogger().d('Department changed to: ${event.departmentId}');

      emit(
        VisitLocationStateLoaded(
          hospitals: currentState.hospitals,
          departments: currentState.departments,
          doctors: currentState.doctors,
          selectedHospitalId: currentState.selectedHospitalId,
          selectedDepartmentId: event.departmentId,
          selectedDoctorId: null, // Clear doctor when department changes
          newestHospital: currentState.newestHospital,
          newDepartmentId: currentState.newDepartmentId,
          newDoctorId: currentState.newDoctorId,
        ),
      );
    }
  }

  Future<void> _updateDepartmentOptions() async {
    try {
      final hospitalId = state is VisitLocationStateLoaded
          ? (state as VisitLocationStateLoaded).selectedHospitalId
          : null;

      if (hospitalId != null) {
        // Get departments for this hospital by parsing departmentIds
        final hospital = await _database.getHospital(hospitalId);
        if (hospital != null) {
          final departmentIdList = hospital.departmentIds
              .split(',')
              .where((s) => s.isNotEmpty)
              .map(int.parse)
              .toList();

          availableDepartments = [];
          for (final deptId in departmentIdList) {
            final dept = await _database.getDepartmentById(deptId);
            if (dept != null) {
              availableDepartments.add(dept);
            }
          }
        } else {
          availableDepartments = [];
        }
        AppLogger().d(
          'Loaded ${availableDepartments.length} departments for hospital $hospitalId',
        );
      } else {
        availableDepartments = await _database.getAllDepartments();
        AppLogger().d('Loaded all ${availableDepartments.length} departments');
      }
    } catch (e) {
      AppLogger().e('Failed to update department options: $e');
    }
  }

  void _updateDoctorOptions() {
    try {
      final currentState = state;
      if (currentState is! VisitLocationStateLoaded) return;

      final hospitalId = currentState.selectedHospitalId;
      final departmentId = currentState.selectedDepartmentId;

      if (hospitalId != null && departmentId != null) {
        availableDoctors = allDoctors
            .where(
              (d) =>
                  d.hospitalId == hospitalId && d.departmentId == departmentId,
            )
            .toList();
        AppLogger().d(
          'Filtered doctors: ${availableDoctors.length} for hospital $hospitalId, department $departmentId',
        );
      } else if (hospitalId != null) {
        availableDoctors = allDoctors
            .where((d) => d.hospitalId == hospitalId)
            .toList();
        AppLogger().d(
          'Filtered doctors: ${availableDoctors.length} for hospital $hospitalId',
        );
      } else {
        availableDoctors = allDoctors;
        AppLogger().d('Using all ${availableDoctors.length} doctors');
      }
    } catch (e) {
      AppLogger().e('Failed to update doctor options: $e');
    }
  }

  String _calculateDoctorLevel(String? title, String? specialty) {
    if (title != null) {
      if (title.toLowerCase().contains('senior') ||
          title.toLowerCase().contains('chief') ||
          title.toLowerCase().contains('head')) {
        return 'Senior';
      } else if (title.toLowerCase().contains('junior') ||
          title.toLowerCase().contains('associate')) {
        return 'Junior';
      }
    }
    return 'General';
  }

  @override
  Future<void> close() async {
    _fieldHelper.dispose();
    return super.close();
  }
}
