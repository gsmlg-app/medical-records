# app_backup

Backup and restore services for medical records application.

## Overview

This package provides comprehensive data export and import functionality for the medical records application, allowing users to backup their data to ZIP files and restore it later. The package ensures data integrity through transaction-based imports and comprehensive validation.

## Features

### Data Export
- **Multiple Export Modes**: Export individual treatments, date ranges, or all data
- **ZIP Archive Format**: Standard ZIP files with manifest.json and resource files
- **Platform Support**: Web, Android, iOS, macOS, Windows, Linux
- **ISO8601 Compliance**: Standard datetime formats for portability
- **Resource Handling**: Automatic inclusion of images, PDFs, and documents

### Data Import
- **Conflict Detection**: Identifies existing data based on title and date range
- **Conflict Resolution**: Three strategies (skip, override, create new)
- **Transaction Safety**: Atomic operations with automatic rollback on failure
- **Comprehensive Validation**: Validates all data before database insertion
- **Relationship Preservation**: Maintains hospital, department, doctor associations

### Data Validation
- **Required Fields**: Validates presence and data types
- **String Lengths**: Enforces 1-255 character limits
- **DateTime Formats**: ISO8601 validation
- **Enum Values**: visit categories, resource types
- **Business Rules**: endDate > startDate, valid JSON structures

## Architecture

```
app_backup/
├── lib/
│   ├── app_backup.dart           # Main export file
│   └── src/
│       ├── data_export_service.dart  # Export functionality
│       ├── data_import_service.dart  # Import functionality
│       └── data_validation.dart      # Data validation layer
└── test/
    ├── data_export_import_integration_test.dart  # Integration tests
    ├── fixtures/
    │   └── sample_data.dart          # Test data generators
    └── helpers/
        └── test_helpers.dart         # Test utilities
```

## Usage

### Export Data

```dart
import 'package:app_backup/app_backup.dart';

final exportService = DataExportService(database);

// Export specific treatments
final zipFile = await exportService.exportTreatments([treatmentId1, treatmentId2]);

// Export by date range
final zipFile = await exportService.exportTreatmentsByDateRange(
  DateTime(2024, 1, 1),
  DateTime(2024, 12, 31),
);

// Export all
final zipFile = await exportService.exportAllTreatments();
```

### Import Data

```dart
import 'package:app_backup/app_backup.dart';

final importService = DataImportService(database);

// Parse ZIP file
final parsedData = await importService.parseZipFile(zipFile);

// Check for conflicts
final conflicts = await importService.checkConflicts(parsedData['manifest']);

// Resolve conflicts and import
await importService.importTreatments(
  parsedData,
  {
    'Treatment Title': ConflictResolution.override,
    'Another Title': ConflictResolution.skip,
  },
);
```

### Validation

```dart
import 'package:app_backup/app_backup.dart';

// Validate treatment data
DataValidator.validateTreatment(treatmentJson);

// Validate visit data
DataValidator.validateVisit(visitJson);

// Validate manifest
DataValidator.validateManifest(manifestJson);
```

## Export File Format

### ZIP Structure
```
medical_records_export_YYYYMMDD_HHMMSS.zip
├── manifest.json          # JSON metadata with all data
└── resources/             # Resource files (images, PDFs)
    ├── {sha256hash}.jpg
    ├── {sha256hash}.pdf
    └── ...
```

### Manifest Schema (Version 1.0)
```json
{
  "version": "1.0",
  "exportDate": "2024-01-15T00:00:00.000Z",
  "treatments": [
    {
      "treatment": {
        "id": 1,
        "title": "Heart Disease Treatment",
        "diagnosis": "Diagnosed with coronary artery disease",
        "startDate": "2024-01-15T00:00:00.000Z",
        "endDate": "2024-06-15T00:00:00.000Z",
        "createdAt": "2024-01-15T00:00:00.000Z",
        "updatedAt": "2024-01-15T00:00:00.000Z"
      },
      "visits": [ /* visit objects */ ],
      "resources": [ /* resource objects */ ],
      "hospital": { /* hospital object */ },
      "department": { /* department object */ },
      "doctor": { /* doctor object */ }
    }
  ]
}
```

## Data Safety Features

### Transaction Support
All import operations are wrapped in database transactions. If any part of the import fails, all changes are automatically rolled back, preventing partial/corrupt imports.

```dart
await _database.transaction(() async {
  // All import operations here
  // If any fail, everything rolls back
});
```

### Cascade Delete
When overriding existing data, the service properly deletes all related entities (visits, resources) before deleting treatments, preventing orphaned data.

### Comprehensive Logging
All operations are logged with structured logging for debugging and audit trails.

## Testing

The package includes comprehensive integration tests covering:

- ✅ Data integrity round-trip verification
- ✅ Multiple treatment separation
- ✅ Null field preservation
- ✅ Large dataset handling (10+ treatments)
- ✅ All three conflict resolution strategies
- ✅ ZIP structure validation
- ✅ Empty export handling

**Test Coverage: 11/11 tests passing (100%)**

Run tests:
```bash
cd app_lib/backup
flutter test
```

## Dependencies

### Internal Packages
- `app_database` - Database access
- `app_logging` - Structured logging
- `app_storage` - Resource file storage

### External Packages
- `archive` - ZIP file creation/extraction
- `path_provider` - System directory access
- `crypto` - SHA256 hashing
- `drift` - Database operations

## Migration from app_storage

If you previously used export/import from `app_storage`:

**Before:**
```dart
import 'package:app_storage/app_storage.dart';
```

**After:**
```dart
import 'package:app_backup/app_backup.dart';
```

The API remains unchanged. Update your imports and rebuild.

## Contributing

This package follows clean architecture principles with:
- Separation of concerns (export, import, validation)
- Transaction-based operations
- Comprehensive error handling
- Extensive test coverage

## License

This is part of the medical records application. All rights reserved.
