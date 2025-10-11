import 'package:app_database/app_database.dart';
import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';

import 'event.dart';
import 'state.dart';

class DepartmentBloc extends Bloc<DepartmentEvent, DepartmentState> {
  final AppDatabase _database;

  DepartmentBloc(this._database) : super(DepartmentInitial()) {
    on<LoadDepartments>(_onLoadDepartments);
    on<AddDepartment>(_onAddDepartment);
    on<UpdateDepartment>(_onUpdateDepartment);
    on<DeleteDepartment>(_onDeleteDepartment);
  }

  Future<void> _onLoadDepartments(
    LoadDepartments event,
    Emitter<DepartmentState> emit,
  ) async {
    emit(DepartmentLoading());
    try {
      final departments = await _database.getAllDepartments();
      emit(DepartmentLoaded(departments));
    } catch (e) {
      emit(DepartmentError('Failed to load departments: ${e.toString()}'));
    }
  }

  Future<void> _onAddDepartment(
    AddDepartment event,
    Emitter<DepartmentState> emit,
  ) async {
    emit(DepartmentLoading());
    try {
      await _database.createDepartment(
        DepartmentsCompanion(
          name: Value(event.name),
          category: Value(event.category),
        ),
      );

      final departments = await _database.getAllDepartments();
      emit(const DepartmentOperationSuccess('Department added successfully'));
      emit(DepartmentLoaded(departments));
    } catch (e) {
      emit(DepartmentError('Failed to add department: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateDepartment(
    UpdateDepartment event,
    Emitter<DepartmentState> emit,
  ) async {
    emit(DepartmentLoading());
    try {
      await _database.updateDepartment(event.department);

      final departments = await _database.getAllDepartments();
      emit(const DepartmentOperationSuccess('Department updated successfully'));
      emit(DepartmentLoaded(departments));
    } catch (e) {
      emit(DepartmentError('Failed to update department: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteDepartment(
    DeleteDepartment event,
    Emitter<DepartmentState> emit,
  ) async {
    emit(DepartmentLoading());
    try {
      await _database.deleteDepartment(event.departmentId);

      final departments = await _database.getAllDepartments();
      emit(const DepartmentOperationSuccess('Department deleted successfully'));
      emit(DepartmentLoaded(departments));
    } catch (e) {
      emit(DepartmentError('Failed to delete department: ${e.toString()}'));
    }
  }
}
