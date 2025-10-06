import 'package:app_database/app_database.dart';
import 'package:equatable/equatable.dart';

abstract class DepartmentEvent extends Equatable {
  const DepartmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadDepartments extends DepartmentEvent {
  const LoadDepartments();

  @override
  List<Object?> get props => [];
}

class AddDepartment extends DepartmentEvent {
  final String name;
  final String? category;

  const AddDepartment({
    required this.name,
    this.category,
  });

  @override
  List<Object?> get props => [name, category];
}

class UpdateDepartment extends DepartmentEvent {
  final Department department;

  const UpdateDepartment(this.department);

  @override
  List<Object?> get props => [department];
}

class DeleteDepartment extends DepartmentEvent {
  final int departmentId;

  const DeleteDepartment(this.departmentId);

  @override
  List<Object?> get props => [departmentId];
}