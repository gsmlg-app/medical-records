import 'package:app_database/app_database.dart';
import 'package:app_logging/app_logging.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:visit_bloc/visit_bloc.dart';
import 'package:drift/drift.dart';

part 'event.dart';
part 'state.dart';

/// {@template visit_data_bloc}
/// BLoC for managing visit database operations.
/// {@endtemplate}
class VisitDataBloc extends Bloc<VisitDataEvent, VisitDataState> {
  /// {@macro visit_data_bloc}
  final AppDatabase database;
  final VisitBloc? visitBloc;

  /// {@macro visit_data_bloc}
  VisitDataBloc(this.database, {this.visitBloc})
    : super(const VisitDataStateInitial()) {
    on<CreateVisit>(_onCreateVisit);
    on<UpdateVisitData>(_onUpdateVisitData);
    on<DeleteVisit>(_onDeleteVisit);
    on<LoadVisit>(_onLoadVisit);
  }

  Future<void> _onCreateVisit(
    CreateVisit event,
    Emitter<VisitDataState> emit,
  ) async {
    try {
      emit(const VisitDataStateLoading());

      final visit = VisitsCompanion.insert(
        treatmentId: event.treatmentId,
        category: event.category.value,
        date: event.date,
        details: event.details,
        hospitalId: Value(event.hospitalId),
        departmentId: Value(event.departmentId),
        doctorId: Value(event.doctorId),
      );

      final visitId = await database.createVisit(visit);

      final createdVisit = Visit(
        id: visitId,
        treatmentId: event.treatmentId,
        category: event.category.value,
        date: event.date,
        details: event.details,
        hospitalId: event.hospitalId,
        departmentId: event.departmentId,
        doctorId: event.doctorId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Notify VisitBloc if available
      visitBloc?.add(CreateVisitFromData(createdVisit));

      emit(VisitDataStateSuccess(createdVisit, 'Visit created successfully'));
    } catch (e) {
      AppLogger().e('Failed to create visit: $e');
      emit(VisitDataStateError(e.toString()));
    }
  }

  Future<void> _onUpdateVisitData(
    UpdateVisitData event,
    Emitter<VisitDataState> emit,
  ) async {
    try {
      emit(const VisitDataStateLoading());

      // Check if visit exists
      final existingVisit = await database.getVisit(event.visitId);
      if (existingVisit == null) {
        emit(const VisitDataStateError('Visit not found'));
        return;
      }

      final updateCompanion = VisitsCompanion(
        treatmentId: Value(event.treatmentId),
        category: Value(event.category.value),
        date: Value(event.date),
        details: Value(event.details),
        hospitalId: Value(event.hospitalId),
        departmentId: Value(event.departmentId),
        doctorId: Value(event.doctorId),
        updatedAt: Value(DateTime.now()),
      );

      await database.updateVisitData(event.visitId, updateCompanion);

      final updatedVisit = Visit(
        id: event.visitId,
        treatmentId: event.treatmentId,
        category: event.category.value,
        date: event.date,
        details: event.details,
        hospitalId: event.hospitalId,
        departmentId: event.departmentId,
        doctorId: event.doctorId,
        createdAt: existingVisit.createdAt,
        updatedAt: DateTime.now(),
      );

      // Notify VisitBloc if available
      visitBloc?.add(UpdateVisitFromData(updatedVisit));

      emit(VisitDataStateSuccess(updatedVisit, 'Visit updated successfully'));
    } catch (e) {
      AppLogger().e('Failed to update visit: $e');
      emit(VisitDataStateError(e.toString()));
    }
  }

  Future<void> _onDeleteVisit(
    DeleteVisit event,
    Emitter<VisitDataState> emit,
  ) async {
    try {
      emit(const VisitDataStateLoading());

      // Check if visit exists
      final existingVisit = await database.getVisit(event.visitId);
      if (existingVisit == null) {
        emit(const VisitDataStateError('Visit not found'));
        return;
      }

      // Delete associated resources first
      await database.deleteResourcesByVisitId(event.visitId);

      // Delete the visit
      await database.deleteVisit(event.visitId);

      // Notify VisitBloc if available
      visitBloc?.add(DeleteVisitFromData(event.visitId));

      emit(VisitDataStateSuccess(null, 'Visit deleted successfully'));
    } catch (e) {
      AppLogger().e('Failed to delete visit: $e');
      emit(VisitDataStateError(e.toString()));
    }
  }

  Future<void> _onLoadVisit(
    LoadVisit event,
    Emitter<VisitDataState> emit,
  ) async {
    try {
      emit(const VisitDataStateLoading());

      final visit = await database.getVisit(event.visitId);

      if (visit == null) {
        emit(const VisitDataStateError('Visit not found'));
        return;
      }

      emit(VisitDataStateSuccess(visit, 'Visit loaded successfully'));
    } catch (e) {
      AppLogger().e('Failed to load visit: $e');
      emit(VisitDataStateError(e.toString()));
    }
  }
}
