import 'package:drift/drift.dart';
import '../enums.dart';

@DataClassName('Visit')
class Visits extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get treatmentId => integer()();

  // Custom enum column for visit category
  TextColumn get category => text()();

  DateTimeColumn get date => dateTime()();

  TextColumn get details => text()();

  IntColumn get hospitalId => integer().nullable()();

  IntColumn get departmentId => integer().nullable()();

  IntColumn get doctorId => integer().nullable()();

  TextColumn get informations =>
      text().nullable()(); // JSON field for additional data

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Custom converter for VisitCategory enum
class VisitCategoryConverter extends TypeConverter<VisitCategory, String> {
  const VisitCategoryConverter();

  @override
  VisitCategory fromSql(String fromDb) {
    switch (fromDb) {
      case 'outpatient':
        return VisitCategory.outpatient;
      case 'inpatient':
        return VisitCategory.inpatient;
      default:
        return VisitCategory.outpatient; // Default value
    }
  }

  @override
  String toSql(VisitCategory value) {
    return value.value;
  }
}
