# Medical Records Data Export/Import Guide

## Table of Contents
1. [Introduction](#introduction)
2. [User Guide](#user-guide)
3. [Export File Format](#export-file-format)
4. [Data Schema Reference](#data-schema-reference)
5. [Complete JSON Example](#complete-json-example)
6. [Import Behavior](#import-behavior)
7. [Advanced Topics](#advanced-topics)
8. [Technical Details](#technical-details)

---

## Introduction

The Medical Records application provides comprehensive data export and import functionality, allowing you to:

- **Backup your medical data** in a portable, structured format
- **Transfer data** between devices or installations
- **Share treatment records** with healthcare providers or family members
- **Archive historical records** for long-term storage

### Version Compatibility
- **Export Format Version**: 1.0
- **Supported Platforms**: Android, iOS, macOS, Windows, Linux, Web
- **File Format**: ZIP archive containing JSON manifest and resource files

### Key Features
- Export individual treatments, date ranges, or all data
- Full data preservation including visits, resources, and related entities
- Conflict detection and resolution during import
- Platform-adaptive file saving (directory picker on mobile, file dialog on desktop)

---

## User Guide

### Exporting Data

#### Accessing the Export Feature
1. Navigate to **Settings** screen
2. Tap **Data Management** section
3. Select **Export Data**

#### Export Modes

**1. Individual Selection**
- Select specific treatments using checkboxes
- Use "Select All" / "Deselect All" for bulk operations
- See treatment count: "X of Y selected"
- Each treatment shows: title, date range, diagnosis

**2. Date Range**
- Tap "Select Date Range" button
- Choose start and end dates from calendar picker
- All treatments starting within this range will be exported

**3. Export All**
- Exports all treatments in the database
- Shows total count before export
- Recommended for full backups

#### Platform-Specific Saving

**Android & iOS**:
- Directory picker appears to choose save location
- If picker unavailable, saves to app's Documents directory
- Success message shows full file path

**Web**:
- Browser's download dialog appears
- File downloads to default Downloads folder
- Standard browser file naming

**Desktop (macOS, Windows, Linux)**:
- Native file save dialog appears
- Choose exact location and filename
- Default filename: `medical_records_export_YYYYMMDD_HHMMSS.zip`

### Importing Data

#### Accessing the Import Feature
1. Navigate to **Settings** screen
2. Tap **Data Management** section
3. Select **Import Data**

#### Import Process

**Step 1: Select File**
- Tap "Browse..." button
- Select a `.zip` file exported from Medical Records
- File is validated automatically

**Step 2: Preview Import**
- View export date and treatment count
- See list of treatments with visit/resource counts
- Verify data before importing

**Step 3: Resolve Conflicts** (if any)
- Conflicts occur when a treatment with the same **title and date range** exists
- For each conflict, choose one action:
  - **Skip**: Don't import this treatment
  - **Override**: Delete existing treatment and import new one
  - **Create New**: Import as a new treatment with new ID

**Step 4: Import**
- Tap "Import Data" button
- Progress indicator shows during import
- Success message confirms completion

---

## Export File Format

### ZIP Archive Structure

```
medical_records_export_20251023_143022.zip
├── manifest.json          # All treatment/visit/hospital/dept/doctor data
└── resources/             # All resource files (images, documents, etc.)
    ├── a7f3e9c8d2b1...45f.jpg
    ├── 1e8f7a6c9b3d...82a.pdf
    └── ...
```

### File Naming Convention

**Export ZIP File**:
- Format: `medical_records_export_YYYYMMDD_HHMMSS.zip`
- Example: `medical_records_export_20251023_143022.zip`

**Resource Files**:
- Format: `{sha256_hash}.{extension}`
- Example: `a7f3e9c8d2b1f4a5e6c7d8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9.jpg`
- Files are named using SHA256 hash of content for deduplication

### manifest.json Structure

```json
{
  "version": "1.0",
  "exportDate": "2025-10-23T14:30:22.123Z",
  "treatments": [
    {
      "treatment": { /* Treatment object */ },
      "visits": [ /* Array of Visit objects */ ],
      "resources": [ /* Array of Resource objects */ ],
      "hospital": { /* Hospital object or null */ },
      "department": { /* Department object or null */ },
      "doctor": { /* Doctor object or null */ }
    }
  ]
}
```

---

## Data Schema Reference

For complete database schema details, see [DATA.md](DATA.md).

### Treatment Object

```json
{
  "id": 1,
  "title": "Annual Physical Examination",
  "diagnosis": "General health checkup",
  "startDate": "2025-01-15T00:00:00.000Z",
  "endDate": "2025-01-15T00:00:00.000Z",
  "createdAt": "2025-01-15T09:00:00.000Z",
  "updatedAt": "2025-01-15T09:00:00.000Z"
}
```

**Fields**:
- `id`: Integer, unique identifier (reassigned on import)
- `title`: String, treatment title (1-255 chars)
- `diagnosis`: String, diagnosis information
- `startDate`: ISO8601 DateTime, treatment start date
- `endDate`: ISO8601 DateTime or null, treatment end date (null = ongoing)
- `createdAt`, `updatedAt`: ISO8601 DateTime, timestamps

### Visit Object

```json
{
  "id": 10,
  "treatmentId": 1,
  "category": "outpatient",
  "date": "2025-01-15T10:00:00.000Z",
  "details": "Routine checkup, blood pressure normal",
  "hospitalId": 5,
  "departmentId": 12,
  "doctorId": 23,
  "informations": null,
  "createdAt": "2025-01-15T10:00:00.000Z",
  "updatedAt": "2025-01-15T10:00:00.000Z"
}
```

**Fields**:
- `id`: Integer, unique identifier (reassigned on import)
- `treatmentId`: Integer, references treatment
- `category`: String enum, "outpatient" or "inpatient"
- `date`: ISO8601 DateTime, visit date
- `details`: String, visit notes and details
- `hospitalId`: Integer or null, references hospital
- `departmentId`: Integer or null, references department
- `doctorId`: Integer or null, references doctor
- `informations`: String or null, JSON field for additional data
- `createdAt`, `updatedAt`: ISO8601 DateTime, timestamps

### Resource Object

```json
{
  "id": 100,
  "visitId": 10,
  "type": "image",
  "filePath": "a7f3e9c8d2b1f4a5e6c7d8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9.jpg",
  "notes": "X-ray chest front view",
  "createdAt": "2025-01-15T11:00:00.000Z",
  "updatedAt": "2025-01-15T11:00:00.000Z"
}
```

**Fields**:
- `id`: Integer, unique identifier (reassigned on import)
- `visitId`: Integer, references visit
- `type`: String enum, one of: "image", "document", "video", "audio", "other"
- `filePath`: String, path to file in resources folder (SHA256-based filename)
- `notes`: String or null, user notes about the resource
- `createdAt`, `updatedAt`: ISO8601 DateTime, timestamps

### Hospital Object

```json
{
  "id": 5,
  "name": "Central General Hospital",
  "address": "123 Medical Center Drive",
  "type": "General Hospital",
  "level": "Class A Grade 3",
  "departmentIds": "[12, 13, 14]",
  "createdAt": "2025-01-10T08:00:00.000Z",
  "updatedAt": "2025-01-10T08:00:00.000Z"
}
```

**Fields**:
- `id`: Integer, unique identifier (reassigned on import)
- `name`: String, hospital name (unique, 1-255 chars)
- `address`: String or null, hospital address
- `type`: String or null, hospital type (e.g., "General Hospital")
- `level`: String or null, hospital classification (e.g., "Class A Grade 3")
- `departmentIds`: String, JSON-encoded array of department IDs
- `createdAt`, `updatedAt`: ISO8601 DateTime, timestamps

### Department Object

```json
{
  "id": 12,
  "name": "Cardiology",
  "category": "Clinical Department"
}
```

**Fields**:
- `id`: Integer, unique identifier (reassigned on import)
- `name`: String, department name (unique, 1-255 chars)
- `category`: String or null, department category

### Doctor Object

```json
{
  "id": 23,
  "hospitalId": 5,
  "departmentId": 12,
  "name": "Dr. Sarah Johnson",
  "level": "Attending Physician",
  "createdAt": "2025-01-10T09:00:00.000Z",
  "updatedAt": "2025-01-10T09:00:00.000Z"
}
```

**Fields**:
- `id`: Integer, unique identifier (reassigned on import)
- `hospitalId`: Integer, references hospital
- `departmentId`: Integer, references department
- `name`: String, doctor's name (1-255 chars)
- `level`: String or null, professional level (e.g., "Attending Physician")
- `createdAt`, `updatedAt`: ISO8601 DateTime, timestamps

---

## Complete JSON Example

```json
{
  "version": "1.0",
  "exportDate": "2025-10-23T14:30:22.456Z",
  "treatments": [
    {
      "treatment": {
        "id": 1,
        "title": "Cardiac Health Monitoring",
        "diagnosis": "Hypertension management",
        "startDate": "2025-01-15T00:00:00.000Z",
        "endDate": null,
        "createdAt": "2025-01-15T09:00:00.000Z",
        "updatedAt": "2025-01-20T14:30:00.000Z"
      },
      "visits": [
        {
          "id": 10,
          "treatmentId": 1,
          "category": "outpatient",
          "date": "2025-01-15T10:00:00.000Z",
          "details": "Initial consultation. BP: 145/92. Prescribed medication.",
          "hospitalId": 5,
          "departmentId": 12,
          "doctorId": 23,
          "informations": null,
          "createdAt": "2025-01-15T10:00:00.000Z",
          "updatedAt": "2025-01-15T10:00:00.000Z"
        },
        {
          "id": 11,
          "treatmentId": 1,
          "category": "outpatient",
          "date": "2025-01-22T11:00:00.000Z",
          "details": "Follow-up visit. BP: 138/88. Medication working well.",
          "hospitalId": 5,
          "departmentId": 12,
          "doctorId": 23,
          "informations": null,
          "createdAt": "2025-01-22T11:00:00.000Z",
          "updatedAt": "2025-01-22T11:00:00.000Z"
        }
      ],
      "resources": [
        {
          "id": 100,
          "visitId": 10,
          "type": "image",
          "filePath": "a7f3e9c8d2b1f4a5e6c7d8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9.jpg",
          "notes": "ECG results - normal sinus rhythm",
          "createdAt": "2025-01-15T11:00:00.000Z",
          "updatedAt": "2025-01-15T11:00:00.000Z"
        },
        {
          "id": 101,
          "visitId": 10,
          "type": "document",
          "filePath": "1e8f7a6c9b3d2f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8.pdf",
          "notes": "Lab report - lipid panel",
          "createdAt": "2025-01-15T11:30:00.000Z",
          "updatedAt": "2025-01-15T11:30:00.000Z"
        }
      ],
      "hospital": {
        "id": 5,
        "name": "Central General Hospital",
        "address": "123 Medical Center Drive",
        "type": "General Hospital",
        "level": "Class A Grade 3",
        "departmentIds": "[12, 13, 14, 15]",
        "createdAt": "2025-01-10T08:00:00.000Z",
        "updatedAt": "2025-01-10T08:00:00.000Z"
      },
      "department": {
        "id": 12,
        "name": "Cardiology",
        "category": "Clinical Department"
      },
      "doctor": {
        "id": 23,
        "hospitalId": 5,
        "departmentId": 12,
        "name": "Dr. Sarah Johnson",
        "level": "Attending Physician",
        "createdAt": "2025-01-10T09:00:00.000Z",
        "updatedAt": "2025-01-10T09:00:00.000Z"
      }
    }
  ]
}
```

---

## Import Behavior

### Conflict Detection

A conflict occurs when an imported treatment matches an existing treatment based on:
- **Treatment title** (case-insensitive comparison)
- **Date range** (start date and end date must both match exactly)

**Example Conflict**:
- Existing: "Annual Checkup", Start: 2025-01-15, End: 2025-01-15
- Import: "annual checkup", Start: 2025-01-15, End: 2025-01-15
- **Result**: Conflict detected (same title and dates)

**No Conflict**:
- Existing: "Annual Checkup", Start: 2025-01-15, End: 2025-01-15
- Import: "Annual Checkup", Start: 2025-02-15, End: 2025-02-15
- **Result**: No conflict (different dates)

### Conflict Resolution Options

**1. Skip**
- Does not import the conflicting treatment
- Existing treatment remains unchanged
- No new data is added

**2. Override**
- Deletes the existing treatment and all its related data (visits, resources)
- Imports the new treatment with fresh IDs
- Resource files are copied to app storage
- Use when the imported data is more complete or accurate

**3. Create New**
- Imports the treatment as a completely new record
- Assigns new IDs to treatment, visits, and resources
- Both old and new treatments coexist in the database
- Use when you want to keep both versions

### ID Assignment

**On Import**:
- All IDs from the export file are ignored
- New auto-increment IDs are assigned by the database
- This ensures no ID conflicts with existing data
- Relationships are maintained using the newly assigned IDs

### Resource File Migration

**Process**:
1. Resource files are extracted from the ZIP archive
2. Each file is verified to exist
3. Files are copied to the app's resource storage directory
4. File paths are updated in the database to reference new locations
5. Original SHA256-based filenames are preserved

**Storage Locations**:
- Files are stored using SHA256 hash of content
- Location: App's support directory + `resources/` + visit ID + filename
- Example: `~/Library/Application Support/medical_records/resources/10/a7f3e9c8...jpg`

### Data Integrity Validation

**During Import**:
- ✅ ZIP file structure is validated
- ✅ manifest.json is parsed and schema-validated
- ✅ Version compatibility is checked
- ✅ Required fields are verified
- ✅ Date formats are validated (ISO8601)
- ✅ Enum values are checked (visit category, resource type)
- ✅ Resource files referenced in manifest exist in archive

**Error Handling**:
- Invalid ZIP structure → Error: "Invalid export file: manifest.json not found"
- Malformed JSON → Error: "Failed to parse zip file: ..."
- Missing resource file → Warning logged, import continues
- Conflict without resolution → Error: "Please resolve all conflicts before importing"

---

## Advanced Topics

### Manual ZIP File Creation

You can manually create export files for custom data:

1. **Create manifest.json**:
   - Follow the exact schema shown in examples
   - Use 2-space indentation for readability
   - Ensure all dates are in ISO8601 format
   - Include all required fields

2. **Add resource files**:
   - Create a `resources/` folder
   - Name files using SHA256 hash of content
   - Reference exact filenames in manifest

3. **Create ZIP archive**:
   ```bash
   zip -r medical_records_export_20251023_143022.zip manifest.json resources/
   ```

### Editing manifest.json

**Safe Edits**:
- ✅ Change treatment titles, diagnosis, details
- ✅ Modify dates (keep ISO8601 format)
- ✅ Update notes and descriptions
- ✅ Remove entire treatments from the array
- ✅ Change resource notes

**Unsafe Edits** (may cause import failure):
- ❌ Changing ID structure or types
- ❌ Removing required fields
- ❌ Invalid date formats
- ❌ Incorrect enum values
- ❌ Malformed JSON syntax
- ❌ Resource file paths that don't exist

### Troubleshooting Common Issues

**Problem**: "Invalid export file: manifest.json not found"
- **Cause**: ZIP file doesn't contain manifest.json at root level
- **Solution**: Ensure manifest.json is at the root, not in a subfolder

**Problem**: "Failed to parse zip file: FormatException"
- **Cause**: Malformed JSON in manifest.json
- **Solution**: Validate JSON syntax using an online validator

**Problem**: Resource file not found during import
- **Cause**: File referenced in manifest doesn't exist in resources/ folder
- **Solution**: Ensure all files in manifest exist in the ZIP's resources/ folder

**Problem**: Import hangs or takes very long
- **Cause**: Large number of resources or very large files
- **Solution**: Split export into smaller date ranges, compress images before adding

**Problem**: "Directory picker not available" on Android
- **Cause**: File picker plugin doesn't support directory selection on device
- **Solution**: File is automatically saved to app's Documents directory, path shown in success message

### File Size Considerations

**Large Exports**:
- Each resource file adds to ZIP size
- Images can be 1-10 MB each
- Videos can be very large (50+ MB)
- Consider exporting in smaller date ranges for large datasets

**Recommendations**:
- Compress images before adding as resources
- Use document format instead of images when possible
- Archive old data separately
- Keep active treatment exports under 100 MB for easy sharing

### Platform-Specific Storage Locations

**Android**:
- Selected directory (via picker): User's choice
- Fallback: `/data/data/app.gsmlg.medicalrecords/files/Documents/`

**iOS**:
- Selected directory (via picker): User's choice
- Fallback: App's Documents directory (accessible via Files app)

**macOS**:
- User-selected location via save dialog
- Default: `~/Downloads/` or last used location

**Windows**:
- User-selected location via save dialog
- Default: `%USERPROFILE%\Downloads\`

**Linux**:
- User-selected location via save dialog
- Default: `~/Downloads/`

**Web**:
- Browser's configured download directory
- Cannot be changed programmatically

---

## Technical Details

### SHA256-Based Resource File Naming

**Purpose**:
- Deduplication: Identical files share same hash
- Integrity: Verify file hasn't been corrupted
- Uniqueness: Hash collision probability is negligible

**Implementation**:
```dart
import 'package:crypto/crypto.dart';

String getResourceFileName(File file) {
  final bytes = file.readAsBytesSync();
  final hash = sha256.convert(bytes);
  final extension = path.extension(file.path);
  return '$hash$extension';
}
```

**Example**:
- Original: `chest_xray.jpg`
- SHA256: `a7f3e9c8d2b1f4a5e6c7d8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9`
- Stored as: `a7f3e9c8d2b1f4a5e6c7d8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9.jpg`

### JSON Encoding Format

**Pretty-Printed**:
- 2-space indentation
- Newline after each object/array element
- Makes manual editing easier
- Slightly larger file size

**Example**:
```dart
const JsonEncoder.withIndent('  ').convert(manifest);
```

### Archive Format

**ZIP Compression**:
- Standard ZIP format (PKZIP)
- Deflate compression algorithm
- Compatible with all major platforms
- Can be opened with any ZIP utility

**Implementation**:
```dart
import 'package:archive/archive_io.dart';

final encoder = ZipFileEncoder();
encoder.create(zipFilePath);
encoder.addDirectory(exportDir);
encoder.close();
```

### Enum Values

**Visit Category**:
- `outpatient`: Outpatient visit
- `inpatient`: Inpatient admission

**Resource Type**:
- `image`: Image files (JPG, PNG, GIF, etc.)
- `document`: Documents (PDF, DOC, TXT, etc.)
- `video`: Video files (MP4, MOV, etc.)
- `audio`: Audio files (MP3, WAV, etc.)
- `other`: Other file types

### Date/Time Format

**ISO8601**:
- Format: `YYYY-MM-DDTHH:mm:ss.sssZ`
- Example: `2025-10-23T14:30:22.456Z`
- Always in UTC timezone
- Milliseconds included for precision

---

## See Also

- [DATA.md](DATA.md) - Complete database schema documentation
- [CLAUDE.md](CLAUDE.md) - Development guidelines and architecture
- [USAGE.md](USAGE.md) - Application usage guide

---

**Document Version**: 1.0
**Last Updated**: October 23, 2025
**Compatible with**: Medical Records App v1.0+
