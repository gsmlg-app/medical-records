import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:app_database/app_database.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_storage/app_storage.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Represents a conflict when importing data
class ImportConflict {
  final Treatment treatment;
  final Treatment? existingTreatment;

  ImportConflict({
    required this.treatment,
    this.existingTreatment,
  });
}

/// User choice for handling conflicts
enum ConflictResolution {
  skip,
  override,
  createNew,
}

/// Service for importing treatment data from zip files
class DataImportService {
  final AppDatabase _database;
  final ResourceStorageService _storageService = ResourceStorageService();

  DataImportService(this._database);

  /// Parse and validate a zip file
  ///
  /// Returns a map containing the manifest and extracted directory path
  Future<Map<String, dynamic>> parseZipFile(File zipFile) async {
    try {
      AppLogger().d('Parsing zip file: ${zipFile.path}');

      // Create temp directory for extraction
      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory('${tempDir.path}/import_${DateTime.now().millisecondsSinceEpoch}');
      await extractDir.create(recursive: true);

      // Extract zip file
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        final data = file.content as List<int>;

        if (file.isFile) {
          final outputFile = File('${extractDir.path}/$filename');
          await outputFile.create(recursive: true);
          await outputFile.writeAsBytes(data);
        }
      }

      // Read and parse manifest.json
      final manifestFile = File('${extractDir.path}/manifest.json');
      if (!await manifestFile.exists()) {
        throw Exception('Invalid export file: manifest.json not found');
      }

      final manifestContent = await manifestFile.readAsString();
      final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;

      // Validate manifest structure
      if (manifest['version'] == null || manifest['treatments'] == null) {
        throw Exception('Invalid manifest structure');
      }

      AppLogger().i('Zip file parsed successfully, version: ${manifest['version']}');

      return {
        'manifest': manifest,
        'extractDir': extractDir.path,
      };
    } catch (e, stackTrace) {
      AppLogger().e('Failed to parse zip file: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Check for conflicts in the data to be imported
  ///
  /// A conflict occurs when a treatment with the same title and date range exists
  Future<List<ImportConflict>> checkConflicts(Map<String, dynamic> manifest) async {
    final conflicts = <ImportConflict>[];

    final treatmentsData = manifest['treatments'] as List<dynamic>;

    for (final treatmentData in treatmentsData) {
      final treatmentJson = treatmentData['treatment'] as Map<String, dynamic>;

      // Create Treatment object from JSON
      final treatment = Treatment(
        id: treatmentJson['id'] as int,
        title: treatmentJson['title'] as String,
        diagnosis: treatmentJson['diagnosis'] as String,
        startDate: DateTime.parse(treatmentJson['startDate'] as String),
        endDate: treatmentJson['endDate'] != null
            ? DateTime.parse(treatmentJson['endDate'] as String)
            : null,
        createdAt: DateTime.parse(treatmentJson['createdAt'] as String),
        updatedAt: DateTime.parse(treatmentJson['updatedAt'] as String),
      );

      // Check for existing treatment with same title and date range
      final existingTreatment = await _findConflictingTreatment(treatment);

      if (existingTreatment != null) {
        conflicts.add(ImportConflict(
          treatment: treatment,
          existingTreatment: existingTreatment,
        ));
      }
    }

    AppLogger().d('Found ${conflicts.length} conflicts');
    return conflicts;
  }

  /// Find a treatment that conflicts with the given treatment
  ///
  /// Conflicts are based on title and date range
  Future<Treatment?> _findConflictingTreatment(Treatment treatment) async {
    final allTreatments = await _database.getAllTreatments();

    for (final existing in allTreatments) {
      // Check if title matches
      if (existing.title.toLowerCase() != treatment.title.toLowerCase()) {
        continue;
      }

      // Check if date ranges overlap or match
      if (existing.startDate.isAtSameMomentAs(treatment.startDate)) {
        // Check end dates
        if (existing.endDate == null && treatment.endDate == null) {
          return existing;
        }
        if (existing.endDate != null &&
            treatment.endDate != null &&
            existing.endDate!.isAtSameMomentAs(treatment.endDate!)) {
          return existing;
        }
      }
    }

    return null;
  }

  /// Import treatments from parsed manifest
  ///
  /// [parsedData] - Result from parseZipFile
  /// [conflictResolutions] - Map of treatment title to resolution choice
  Future<void> importTreatments(
    Map<String, dynamic> parsedData,
    Map<String, ConflictResolution> conflictResolutions,
  ) async {
    try {
      final manifest = parsedData['manifest'] as Map<String, dynamic>;
      final extractDir = parsedData['extractDir'] as String;

      final treatmentsData = manifest['treatments'] as List<dynamic>;

      for (final treatmentData in treatmentsData) {
        await _importSingleTreatment(
          treatmentData as Map<String, dynamic>,
          extractDir,
          conflictResolutions,
        );
      }

      // Clean up temp directory
      final tempDir = Directory(extractDir);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }

      AppLogger().i('Import completed successfully');
    } catch (e, stackTrace) {
      AppLogger().e('Import failed: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Import a single treatment with all its related data
  Future<void> _importSingleTreatment(
    Map<String, dynamic> treatmentData,
    String extractDir,
    Map<String, ConflictResolution> conflictResolutions,
  ) async {
    final treatmentJson = treatmentData['treatment'] as Map<String, dynamic>;

    final treatment = Treatment(
      id: treatmentJson['id'] as int,
      title: treatmentJson['title'] as String,
      diagnosis: treatmentJson['diagnosis'] as String,
      startDate: DateTime.parse(treatmentJson['startDate'] as String),
      endDate: treatmentJson['endDate'] != null
          ? DateTime.parse(treatmentJson['endDate'] as String)
          : null,
      createdAt: DateTime.parse(treatmentJson['createdAt'] as String),
      updatedAt: DateTime.parse(treatmentJson['updatedAt'] as String),
    );

    // Check for conflict
    final existingTreatment = await _findConflictingTreatment(treatment);
    final resolution = conflictResolutions[treatment.title] ?? ConflictResolution.skip;

    int treatmentId;

    if (existingTreatment != null) {
      // Handle conflict based on resolution
      switch (resolution) {
        case ConflictResolution.skip:
          AppLogger().d('Skipping treatment: ${treatment.title}');
          return;

        case ConflictResolution.override:
          // Delete existing treatment and its related data
          await _database.deleteTreatment(existingTreatment.id);
          // Create new treatment
          treatmentId = await _database.createTreatment(
            TreatmentsCompanion(
              title: drift.Value(treatment.title),
              diagnosis: drift.Value(treatment.diagnosis),
              startDate: drift.Value(treatment.startDate),
              endDate: drift.Value(treatment.endDate),
            ),
          );
          AppLogger().d('Overrode treatment: ${treatment.title} (new ID: $treatmentId)');
          break;

        case ConflictResolution.createNew:
          // Create new treatment with new ID
          treatmentId = await _database.createTreatment(
            TreatmentsCompanion(
              title: drift.Value(treatment.title),
              diagnosis: drift.Value(treatment.diagnosis),
              startDate: drift.Value(treatment.startDate),
              endDate: drift.Value(treatment.endDate),
            ),
          );
          AppLogger().d('Created new treatment: ${treatment.title} (ID: $treatmentId)');
          break;
      }
    } else {
      // No conflict, create new treatment
      treatmentId = await _database.createTreatment(
        TreatmentsCompanion(
          title: drift.Value(treatment.title),
          diagnosis: drift.Value(treatment.diagnosis),
          startDate: drift.Value(treatment.startDate),
          endDate: drift.Value(treatment.endDate),
        ),
      );
      AppLogger().d('Created treatment: ${treatment.title} (ID: $treatmentId)');
    }

    // Import related hospital, department, doctor (if needed)
    int? hospitalId;
    int? departmentId;
    int? doctorId;

    if (treatmentData['hospital'] != null) {
      hospitalId = await _importHospital(treatmentData['hospital'] as Map<String, dynamic>);
    }

    if (treatmentData['department'] != null && hospitalId != null) {
      departmentId = await _importDepartment(
        treatmentData['department'] as Map<String, dynamic>,
        hospitalId,
      );
    }

    if (treatmentData['doctor'] != null && hospitalId != null) {
      doctorId = await _importDoctor(
        treatmentData['doctor'] as Map<String, dynamic>,
        hospitalId,
        departmentId,
      );
    }

    // Import visits
    final visitsData = treatmentData['visits'] as List<dynamic>?;
    if (visitsData != null) {
      for (final visitJson in visitsData) {
        await _importVisit(
          visitJson as Map<String, dynamic>,
          treatmentId,
          hospitalId,
          departmentId,
          doctorId,
        );
      }
    }

    // Import resources
    final resourcesData = treatmentData['resources'] as List<dynamic>?;
    if (resourcesData != null) {
      for (final resourceJson in resourcesData) {
        await _importResource(
          resourceJson as Map<String, dynamic>,
          extractDir,
        );
      }
    }
  }

  Future<int?> _importHospital(Map<String, dynamic> hospitalJson) async {
    final name = hospitalJson['name'] as String;

    // Check if hospital already exists
    final existingHospitals = await _database.getAllHospitals();
    final existing = existingHospitals.where((h) => h.name == name).firstOrNull;

    if (existing != null) {
      return existing.id;
    }

    // Create new hospital
    return await _database.createHospital(
      HospitalsCompanion(
        name: drift.Value(name),
        address: drift.Value(hospitalJson['address'] as String?),
        type: drift.Value(hospitalJson['type'] as String?),
        level: drift.Value(hospitalJson['level'] as String?),
        departmentIds: const drift.Value('[]'), // Empty JSON array
      ),
    );
  }

  Future<int?> _importDepartment(Map<String, dynamic> departmentJson, int hospitalId) async {
    final name = departmentJson['name'] as String;

    // Check if department already exists
    final existingDepartments = await _database.getAllDepartments();
    final existing = existingDepartments
        .where((d) => d.name == name)
        .firstOrNull;

    if (existing != null) {
      return existing.id;
    }

    // Create new department
    return await _database.createDepartment(
      DepartmentsCompanion(
        name: drift.Value(name),
        category: drift.Value(departmentJson['category'] as String?),
      ),
    );
  }

  Future<int?> _importDoctor(
    Map<String, dynamic> doctorJson,
    int hospitalId,
    int? departmentId,
  ) async {
    final name = doctorJson['name'] as String;

    // Check if doctor already exists
    final existingDoctors = await _database.getDoctorsByHospital(hospitalId);
    final existing = existingDoctors.where((d) => d.name == name).firstOrNull;

    if (existing != null) {
      return existing.id;
    }

    // departmentId is required for doctors table
    if (departmentId == null) {
      AppLogger().w('Cannot create doctor without department ID');
      return null;
    }

    // Create new doctor
    return await _database.createDoctor(
      DoctorsCompanion(
        hospitalId: drift.Value(hospitalId),
        departmentId: drift.Value(departmentId),
        name: drift.Value(name),
        level: drift.Value(doctorJson['level'] as String?),
      ),
    );
  }

  Future<void> _importVisit(
    Map<String, dynamic> visitJson,
    int treatmentId,
    int? hospitalId,
    int? departmentId,
    int? doctorId,
  ) async {
    final visitId = await _database.createVisit(
      VisitsCompanion(
        treatmentId: drift.Value(treatmentId),
        category: drift.Value(visitJson['category'] as String),
        date: drift.Value(DateTime.parse(visitJson['date'] as String)),
        details: drift.Value(visitJson['details'] as String),
        hospitalId: drift.Value(hospitalId),
        departmentId: drift.Value(departmentId),
        doctorId: drift.Value(doctorId),
      ),
    );

    AppLogger().d('Created visit ID: $visitId');
  }

  Future<void> _importResource(
    Map<String, dynamic> resourceJson,
    String extractDir,
  ) async {
    final filePath = resourceJson['filePath'] as String;
    final sourceFile = File('$extractDir/resources/${p.basename(filePath)}');

    if (await sourceFile.exists()) {
      // Resource files are stored by SHA256 hash, so we can just copy to storage
      final destFile = await _storageService.getResourceFile(filePath);
      await destFile.parent.create(recursive: true);
      await sourceFile.copy(destFile.path);

      AppLogger().d('Imported resource: $filePath');
    } else {
      AppLogger().w('Resource file not found during import: $filePath');
    }
  }
}
