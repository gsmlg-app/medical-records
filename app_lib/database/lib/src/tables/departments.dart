import 'package:drift/drift.dart';

@DataClassName('Department')
class Departments extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name =>
      text().withLength(min: 1, max: 255).unique()(); // e.g., "Cardiology"

  TextColumn get category => text()
      .nullable()(); // e.g., "Clinical Department", "Medical Technology Department"
}
