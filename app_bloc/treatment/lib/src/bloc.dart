import 'package:app_database/app_database.dart';
import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';

import 'event.dart';
import 'state.dart';

class TreatmentBloc extends Bloc<TreatmentEvent, TreatmentState> {
  final AppDatabase _database;

  TreatmentBloc(this._database) : super(TreatmentInitial()) {
    on<LoadTreatments>(_onLoadTreatments);
    on<AddTreatment>(_onAddTreatment);
    on<UpdateTreatment>(_onUpdateTreatment);
    on<DeleteTreatment>(_onDeleteTreatment);
  }

  Future<void> _onLoadTreatments(LoadTreatments event, Emitter<TreatmentState> emit) async {
    emit(TreatmentLoading());
    try {
      final treatments = await _database.getAllTreatments();
      emit(TreatmentLoaded(treatments));
    } catch (e) {
      emit(TreatmentError('Failed to load treatments: ${e.toString()}'));
    }
  }

  Future<void> _onAddTreatment(AddTreatment event, Emitter<TreatmentState> emit) async {
    emit(TreatmentLoading());
    try {
      await _database.createTreatment(
        TreatmentsCompanion(
          title: Value(event.title),
          diagnosis: Value(event.diagnosis),
          startDate: Value(event.startDate),
          endDate: Value(event.endDate),
        ),
      );

      final treatments = await _database.getAllTreatments();
      emit(TreatmentOperationSuccess('Treatment added successfully'));
      emit(TreatmentLoaded(treatments));
    } catch (e) {
      emit(TreatmentError('Failed to add treatment: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateTreatment(UpdateTreatment event, Emitter<TreatmentState> emit) async {
    emit(TreatmentLoading());
    try {
      final existingTreatment = await _database.getTreatmentById(event.id);
      if (existingTreatment == null) {
        emit(TreatmentError('Treatment not found'));
        return;
      }

      final updatedTreatment = Treatment(
        id: event.id,
        title: event.title,
        diagnosis: event.diagnosis,
        startDate: event.startDate,
        endDate: event.endDate,
        createdAt: existingTreatment.createdAt,
        updatedAt: DateTime.now(),
      );

      await _database.updateTreatment(updatedTreatment);

      final treatments = await _database.getAllTreatments();
      emit(TreatmentOperationSuccess('Treatment updated successfully'));
      emit(TreatmentLoaded(treatments));
    } catch (e) {
      emit(TreatmentError('Failed to update treatment: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteTreatment(DeleteTreatment event, Emitter<TreatmentState> emit) async {
    emit(TreatmentLoading());
    try {
      await _database.deleteTreatment(event.id);

      final treatments = await _database.getAllTreatments();
      emit(TreatmentOperationSuccess('Treatment deleted successfully'));
      emit(TreatmentLoaded(treatments));
    } catch (e) {
      emit(TreatmentError('Failed to delete treatment: ${e.toString()}'));
    }
  }
}
