import 'package:app_database/app_database.dart';
import 'package:equatable/equatable.dart';

abstract class DepartmentState extends Equatable {
  const DepartmentState();

  @override
  List<Object?> get props => [];
}

class DepartmentInitial extends DepartmentState {
  const DepartmentInitial();

  @override
  List<Object?> get props => [];
}

class DepartmentLoading extends DepartmentState {
  const DepartmentLoading();

  @override
  List<Object?> get props => [];
}

class DepartmentLoaded extends DepartmentState {
  final List<Department> departments;

  const DepartmentLoaded(this.departments);

  @override
  List<Object?> get props => [departments];
}

class DepartmentOperationSuccess extends DepartmentState {
  final String message;

  const DepartmentOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class DepartmentError extends DepartmentState {
  final String error;

  const DepartmentError(this.error);

  @override
  List<Object?> get props => [error];
}