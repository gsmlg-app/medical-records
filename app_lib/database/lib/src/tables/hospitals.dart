import 'package:drift/drift.dart';
import '../type_converter.dart';

@DataClassName('Hospital')
class Hospitals extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 255).unique()();

  TextColumn get address => text().nullable()();

  TextColumn get type =>
      text().nullable()(); // e.g., "General Hospital", "Specialty Hospital"

  TextColumn get level =>
      text().nullable()(); // e.g., "Class A Grade 3", "Class B Grade 2"

  TextColumn get departmentIds =>
      text()(); // JSON encoded list of department IDs

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
