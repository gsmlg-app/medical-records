import 'package:app_database/app_database.dart';
import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';

import 'event.dart';
import 'state.dart';

class HospitalBloc extends Bloc<HospitalEvent, HospitalState> {
  final AppDatabase _database;

  HospitalBloc(this._database) : super(HospitalInitial()) {
    on<LoadHospitals>(_onLoadHospitals);
    on<AddHospital>(_onAddHospital);
    on<UpdateHospital>(_onUpdateHospital);
    on<DeleteHospital>(_onDeleteHospital);
  }

  Future<void> _onLoadHospitals(
    LoadHospitals event,
    Emitter<HospitalState> emit,
  ) async {
    emit(HospitalLoading());
    try {
      final hospitals = await _database.getAllHospitals();
      emit(HospitalLoaded(hospitals));
    } catch (e) {
      emit(HospitalError('Failed to load hospitals: ${e.toString()}'));
    }
  }

  Future<void> _onAddHospital(
    AddHospital event,
    Emitter<HospitalState> emit,
  ) async {
    emit(HospitalLoading());
    try {
      await _database.createHospital(
        HospitalsCompanion(
          name: Value(event.name),
          address: Value(event.address),
          type: Value(event.type),
          level: Value(event.level),
          departmentIds: Value('[]'), // Start with empty departments
        ),
      );

      final hospitals = await _database.getAllHospitals();
      emit(HospitalOperationSuccess('Hospital added successfully'));
      emit(HospitalLoaded(hospitals));
    } catch (e) {
      emit(HospitalError('Failed to add hospital: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateHospital(
    UpdateHospital event,
    Emitter<HospitalState> emit,
  ) async {
    emit(HospitalLoading());
    try {
      final existingHospital = await _database.getHospitalById(event.id);
      if (existingHospital == null) {
        emit(HospitalError('Hospital not found'));
        return;
      }

      final updatedHospital = Hospital(
        id: event.id,
        name: event.name,
        address: event.address,
        type: event.type,
        level: event.level,
        departmentIds: existingHospital.departmentIds,
        createdAt: existingHospital.createdAt,
        updatedAt: DateTime.now(),
      );

      await _database.updateHospital(updatedHospital);

      final hospitals = await _database.getAllHospitals();
      emit(HospitalOperationSuccess('Hospital updated successfully'));
      emit(HospitalLoaded(hospitals));
    } catch (e) {
      emit(HospitalError('Failed to update hospital: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteHospital(
    DeleteHospital event,
    Emitter<HospitalState> emit,
  ) async {
    emit(HospitalLoading());
    try {
      await _database.deleteHospital(event.id);

      final hospitals = await _database.getAllHospitals();
      emit(HospitalOperationSuccess('Hospital deleted successfully'));
      emit(HospitalLoaded(hospitals));
    } catch (e) {
      emit(HospitalError('Failed to delete hospital: ${e.toString()}'));
    }
  }
}
