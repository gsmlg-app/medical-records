import 'package:drift/drift.dart';

@DataClassName('Doctor')
class Doctors extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get hospitalId => integer()();

  IntColumn get departmentId => integer()();

  TextColumn get name => text().withLength(min: 1, max: 255)();

  TextColumn get level => text().nullable()(); // e.g., "Attending Physician", "Resident"

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  }