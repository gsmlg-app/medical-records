import 'dart:io';
import 'package:equatable/equatable.dart';

/// Base class for all visit resource events
abstract class VisitResourceEvent extends Equatable {
  const VisitResourceEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load resources for a visit
class LoadResources extends VisitResourceEvent {
  final int visitId;

  const LoadResources(this.visitId);

  @override
  List<Object?> get props => [visitId];

  @override
  String toString() => 'LoadResources(visitId: $visitId)';
}

/// Event to add a new resource
class AddResource extends VisitResourceEvent {
  final File file;
  final int visitId;

  const AddResource(this.file, this.visitId);

  @override
  List<Object?> get props => [file, visitId];

  @override
  String toString() => 'AddResource(file: ${file.path}, visitId: $visitId)';
}

/// Event to remove a resource
class RemoveResource extends VisitResourceEvent {
  final int resourceId;

  const RemoveResource(this.resourceId);

  @override
  List<Object?> get props => [resourceId];

  @override
  String toString() => 'RemoveResource(resourceId: $resourceId)';
}

/// Event to clear all resources
class ClearResources extends VisitResourceEvent {
  final int? visitId; // Optional: if provided, clears from database too

  const ClearResources({this.visitId});

  @override
  List<Object?> get props => [visitId];

  @override
  String toString() => 'ClearResources(visitId: $visitId)';
}
