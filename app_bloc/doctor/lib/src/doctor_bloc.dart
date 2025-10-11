import 'package:app_database/app_database.dart';
import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';

import 'event.dart';
import 'state.dart';

class DoctorBloc extends Bloc<DoctorEvent, DoctorState> {
  final AppDatabase _database;

  DoctorBloc(this._database) : super(DoctorInitial()) {
    on<LoadDoctors>(_onLoadDoctors);
    on<LoadDoctorsByHospital>(_onLoadDoctorsByHospital);
    on<LoadDoctorsByDepartment>(_onLoadDoctorsByDepartment);
    on<LoadDoctorsByHospitalAndDepartment>(
      _onLoadDoctorsByHospitalAndDepartment,
    );
    on<AddDoctor>(_onAddDoctor);
    on<UpdateDoctor>(_onUpdateDoctor);
    on<DeleteDoctor>(_onDeleteDoctor);
  }

  Future<void> _onLoadDoctors(
    LoadDoctors event,
    Emitter<DoctorState> emit,
  ) async {
    emit(DoctorLoading());
    try {
      final doctors = await _database.getAllDoctors();
      emit(DoctorLoaded(doctors));
    } catch (e) {
      emit(DoctorError('Failed to load doctors: ${e.toString()}'));
    }
  }

  Future<void> _onLoadDoctorsByHospital(
    LoadDoctorsByHospital event,
    Emitter<DoctorState> emit,
  ) async {
    emit(DoctorLoading());
    try {
      final doctors = await _database.getDoctorsByHospital(event.hospitalId);
      emit(DoctorLoaded(doctors));
    } catch (e) {
      emit(DoctorError('Failed to load doctors for hospital: ${e.toString()}'));
    }
  }

  Future<void> _onLoadDoctorsByDepartment(
    LoadDoctorsByDepartment event,
    Emitter<DoctorState> emit,
  ) async {
    emit(DoctorLoading());
    try {
      final allDoctors = await _database.getAllDoctors();
      final filteredDoctors = allDoctors
          .where((doctor) => doctor.departmentId == event.departmentId)
          .toList();
      emit(DoctorLoaded(filteredDoctors));
    } catch (e) {
      emit(
        DoctorError('Failed to load doctors for department: ${e.toString()}'),
      );
    }
  }

  Future<void> _onLoadDoctorsByHospitalAndDepartment(
    LoadDoctorsByHospitalAndDepartment event,
    Emitter<DoctorState> emit,
  ) async {
    emit(DoctorLoading());
    try {
      final allDoctors = await _database.getAllDoctors();
      final filteredDoctors = allDoctors
          .where(
            (doctor) =>
                doctor.hospitalId == event.hospitalId &&
                doctor.departmentId == event.departmentId,
          )
          .toList();
      emit(DoctorLoaded(filteredDoctors));
    } catch (e) {
      emit(DoctorError('Failed to load doctors: ${e.toString()}'));
    }
  }

  Future<void> _onAddDoctor(AddDoctor event, Emitter<DoctorState> emit) async {
    emit(DoctorLoading());
    try {
      await _database.createDoctor(
        DoctorsCompanion(
          name: Value(event.name),
          hospitalId: Value(event.hospitalId),
          departmentId: Value(event.departmentId),
          level: Value(event.level),
        ),
      );

      final doctors = await _database.getAllDoctors();
      emit(const DoctorOperationSuccess('Doctor added successfully'));
      emit(DoctorLoaded(doctors));
    } catch (e) {
      emit(DoctorError('Failed to add doctor: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateDoctor(
    UpdateDoctor event,
    Emitter<DoctorState> emit,
  ) async {
    emit(DoctorLoading());
    try {
      await _database.updateDoctor(event.doctor);

      final doctors = await _database.getAllDoctors();
      emit(const DoctorOperationSuccess('Doctor updated successfully'));
      emit(DoctorLoaded(doctors));
    } catch (e) {
      emit(DoctorError('Failed to update doctor: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteDoctor(
    DeleteDoctor event,
    Emitter<DoctorState> emit,
  ) async {
    emit(DoctorLoading());
    try {
      await _database.deleteDoctor(event.doctorId);

      final doctors = await _database.getAllDoctors();
      emit(const DoctorOperationSuccess('Doctor deleted successfully'));
      emit(DoctorLoaded(doctors));
    } catch (e) {
      emit(DoctorError('Failed to delete doctor: ${e.toString()}'));
    }
  }
}
