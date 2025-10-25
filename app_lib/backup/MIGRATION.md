# Migration Guide: app_storage → app_backup

This document details the migration of export/import functionality from `app_storage` to the new `app_backup` package.

## Overview

The export and import functionality has been moved from `app_storage` to a dedicated `app_backup` package to better separate concerns:

- **app_storage**: Resource file storage (images, PDFs, documents)
- **app_backup**: Data export/import and backup/restore functionality

## What Was Moved

### Source Files
From `app_lib/storage/lib/src/`:
- ✅ `data_export_service.dart` → `app_lib/backup/lib/src/`
- ✅ `data_import_service.dart` → `app_lib/backup/lib/src/`
- ✅ `data_validation.dart` → `app_lib/backup/lib/src/`

### Test Files
From `app_lib/storage/test/`:
- ✅ `data_export_import_integration_test.dart` → `app_lib/backup/test/`
- ✅ `fixtures/sample_data.dart` → `app_lib/backup/test/fixtures/`
- ✅ `helpers/test_helpers.dart` → `app_lib/backup/test/helpers/`

## Changes Required

### 1. Import Statements

**Old (app_storage):**
```dart
import 'package:app_storage/app_storage.dart';

final exportService = DataExportService(database);
final importService = DataImportService(database);
```

**New (app_backup):**
```dart
import 'package:app_backup/app_backup.dart';

final exportService = DataExportService(database);
final importService = DataImportService(database);
```

### 2. Dependencies (pubspec.yaml)

**Old:**
```yaml
dependencies:
  app_storage: any
```

**New:**
```yaml
dependencies:
  app_backup: any
```

### 3. Files Updated in Main App

The following files had their imports updated:
- ✅ `/lib/screens/settings/data_export_screen.dart`
- ✅ `/lib/screens/settings/data_import_screen.dart`
- ✅ `/pubspec.yaml` (workspace and dependencies)

### 4. Workspace Configuration

**Updated `/pubspec.yaml`:**
```yaml
workspace:
  - app_lib/storage
  - app_lib/backup  # New package added
  
dependencies:
  app_storage: any
  app_backup: any    # New dependency
```

## API Compatibility

**✅ No API changes** - The public API remains exactly the same:

```dart
// Export
final exportService = DataExportService(database);
final file = await exportService.exportTreatments([id1, id2]);

// Import
final importService = DataImportService(database);
final data = await importService.parseZipFile(file);
await importService.importTreatments(data, resolutions);

// Validation
DataValidator.validateTreatment(json);
DataValidator.validateVisit(json);
```

## Testing

All tests were migrated and continue to pass:

```bash
# Run backup package tests
cd app_lib/backup
flutter test

# Result: 11/11 tests passing (100%)
```

## Benefits of Separation

### Before (Single Package)
```
app_storage/
├── resource_storage_service.dart  # Resource files
├── data_export_service.dart       # Backup/export
├── data_import_service.dart       # Backup/import
└── data_validation.dart           # Validation
```
**Problem**: Mixed concerns - storage and backup in one package

### After (Separated)
```
app_storage/                app_backup/
├── resource_storage.dart   ├── data_export_service.dart
                           ├── data_import_service.dart
                           └── data_validation.dart
```
**Benefits:**
- ✅ Clear separation of concerns
- ✅ Independent versioning
- ✅ Easier to test and maintain
- ✅ Better dependency management
- ✅ Follows single responsibility principle

## Rollback Instructions

If you need to rollback this change:

1. Restore `app_storage/lib/app_storage.dart`:
   ```dart
   export 'src/resource_storage_service.dart';
   export 'src/data_export_service.dart';     // Add back
   export 'src/data_import_service.dart';    // Add back
   export 'src/data_validation.dart';        // Add back
   ```

2. Update imports in app screens back to:
   ```dart
   import 'package:app_storage/app_storage.dart';
   ```

3. Remove `app_lib/backup` from workspace in `pubspec.yaml`

4. Run: `melos bootstrap`

## Verification Checklist

After migration, verify:

- [x] All 11 backup tests pass
- [x] Main app compiles without errors
- [x] Export screen works correctly
- [x] Import screen works correctly
- [x] No references to old `app_storage` exports remain
- [x] Melos workspace includes new package (31 packages)

## Questions?

If you encounter issues after migration:

1. **Import errors**: Make sure you've updated all `app_storage` imports to `app_backup`
2. **Missing dependencies**: Run `melos bootstrap` from project root
3. **Test failures**: Check that test imports reference `app_backup`

## Timeline

- **Created**: January 2025
- **Status**: ✅ Complete
- **Tests**: 11/11 passing
- **Breaking Changes**: None (API compatible)

