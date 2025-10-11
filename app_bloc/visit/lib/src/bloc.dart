import 'package:app_database/app_database.dart';
import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';

import 'event.dart';
import 'state.dart';

class VisitBloc extends Bloc<VisitEvent, VisitState> {
  final AppDatabase _database;
  int? _currentTreatmentId;

  VisitBloc(this._database) : super(VisitInitial()) {
    on<LoadVisits>(_onLoadVisits);
    on<LoadVisitsByTreatment>(_onLoadVisitsByTreatment);
    on<AddVisit>(_onAddVisit);
    on<UpdateVisit>(_onUpdateVisit);
    on<DeleteVisit>(_onDeleteVisit);
  }

  Future<void> _onLoadVisits(LoadVisits event, Emitter<VisitState> emit) async {
    _currentTreatmentId = null; // Reset filter
    emit(VisitLoading());
    try {
      final visits = await _database.getAllVisits();
      emit(VisitLoaded(visits));
    } catch (e) {
      emit(VisitError('Failed to load visits: ${e.toString()}'));
    }
  }

  Future<void> _onLoadVisitsByTreatment(LoadVisitsByTreatment event, Emitter<VisitState> emit) async {
    _currentTreatmentId = event.treatmentId; // Remember current filter
    emit(VisitLoading());
    try {
      final visits = await _database.getVisitsByTreatment(event.treatmentId);
      emit(VisitLoaded(visits));
    } catch (e) {
      emit(VisitError('Failed to load visits for treatment: ${e.toString()}'));
    }
  }

  Future<void> _onAddVisit(AddVisit event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    try {
      await _database.createVisit(
        VisitsCompanion(
          treatmentId: Value(event.treatmentId),
          category: Value(event.category.value),
          date: Value(event.date),
          details: Value(event.details),
          hospitalId: Value(event.hospitalId),
          departmentId: Value(event.departmentId),
          doctorId: Value(event.doctorId),
          informations: Value(event.informations),
        ),
      );

      // Reload visits using the current filter to maintain consistency
      List<Visit> visits;
      if (_currentTreatmentId != null) {
        // If we have a treatment filter, reload filtered visits
        visits = await _database.getVisitsByTreatment(_currentTreatmentId!);
      } else {
        // Otherwise load all visits
        visits = await _database.getAllVisits();
      }
      
      emit(VisitOperationSuccess('Visit added successfully'));
      emit(VisitLoaded(visits));
    } catch (e) {
      emit(VisitError('Failed to add visit: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateVisit(UpdateVisit event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    try {
      final existingVisit = await _database.getVisitById(event.id);
      if (existingVisit == null) {
        emit(VisitError('Visit not found'));
        return;
      }

      final updatedVisit = Visit(
        id: event.id,
        treatmentId: event.treatmentId,
        category: event.category.value,
        date: event.date,
        details: event.details,
        hospitalId: event.hospitalId,
        departmentId: event.departmentId,
        doctorId: event.doctorId,
        informations: event.informations,
        createdAt: existingVisit.createdAt,
        updatedAt: DateTime.now(),
      );

      await _database.updateVisit(updatedVisit);

      // Reload visits using the current filter to maintain consistency
      List<Visit> visits;
      if (_currentTreatmentId != null) {
        // If we have a treatment filter, reload filtered visits
        visits = await _database.getVisitsByTreatment(_currentTreatmentId!);
      } else {
        // Otherwise load all visits
        visits = await _database.getAllVisits();
      }
      
      emit(VisitOperationSuccess('Visit updated successfully'));
      emit(VisitLoaded(visits));
    } catch (e) {
      emit(VisitError('Failed to update visit: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteVisit(DeleteVisit event, Emitter<VisitState> emit) async {
    emit(VisitLoading());
    try {
      await _database.deleteVisit(event.id);

      // Reload visits using the current filter to maintain consistency
      List<Visit> visits;
      if (_currentTreatmentId != null) {
        // If we have a treatment filter, reload filtered visits
        visits = await _database.getVisitsByTreatment(_currentTreatmentId!);
      } else {
        // Otherwise load all visits
        visits = await _database.getAllVisits();
      }
      
      emit(VisitOperationSuccess('Visit deleted successfully'));
      emit(VisitLoaded(visits));
    } catch (e) {
      emit(VisitError('Failed to delete visit: ${e.toString()}'));
    }
  }
}
