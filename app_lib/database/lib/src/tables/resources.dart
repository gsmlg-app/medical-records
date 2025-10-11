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

  TextColumn get notes => text().nullable()();

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
