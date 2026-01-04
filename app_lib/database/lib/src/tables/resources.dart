import 'package:drift/drift.dart';
import '../enums.dart';

@DataClassName('Resource')
class Resources extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get visitId => integer()();

  // Custom enum column for resource type
  TextColumn get type => text()();

  TextColumn get filePath =>
      text().withLength(min: 1, max: 500)(); // Local storage path

  // User-defined name for the resource
  TextColumn get name => text().nullable()();

  TextColumn get notes => text().nullable()();

  // Rotation in degrees (0, 90, 180, 270) for image orientation
  IntColumn get rotation => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Custom converter for ResourceType enum
class ResourceTypeConverter extends TypeConverter<ResourceType, String> {
  const ResourceTypeConverter();

  @override
  ResourceType fromSql(String fromDb) {
    switch (fromDb) {
      case 'image':
        return ResourceType.image;
      case 'document':
        return ResourceType.document;
      case 'video':
        return ResourceType.video;
      case 'audio':
        return ResourceType.audio;
      case 'other':
        return ResourceType.other;
      default:
        return ResourceType.other; // Default value
    }
  }

  @override
  String toSql(ResourceType value) {
    return value.value;
  }
}
