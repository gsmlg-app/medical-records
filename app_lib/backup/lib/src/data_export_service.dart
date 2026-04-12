import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:app_database/app_database.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_storage/app_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service for exporting treatment data to zip files
class DataExportService {
  final AppDatabase _database;
  final ResourceStorageService _storageService = ResourceStorageService();

  DataExportService(this._database);

  /// Export selected treatments to a zip file
  ///
  /// [treatmentIds] - List of treatment IDs to export
  /// Returns the path to the created zip file
  Future<File> exportTreatments(List<int> treatmentIds) async {
    try {
      AppLogger().d('Starting export of ${treatmentIds.length} treatments');

      // Create temp directory for export
      final tempDir = await getTemporaryDirectory();
      final exportDir = Directory(
        '${tempDir.path}/export_${DateTime.now().millisecondsSinceEpoch}',
      );
      await exportDir.create(recursive: true);

      final resourcesDir = Directory('${exportDir.path}/resources');
      await resourcesDir.create();

      // Collect all data
      final exportData = <Map<String, dynamic>>[];

      for (final treatmentId in treatmentIds) {
        AppLogger().d('Exporting treatment $treatmentId');

        // Fetch treatment
        final treatment = await _database.getTreatmentById(treatmentId);
        if (treatment == null) {
          AppLogger().w('Treatment $treatmentId not found, skipping');
          continue;
        }

        // Fetch all visits for this treatment
        final visits = await _database.getVisitsByTreatment(treatmentId);

        // Collect all resources and related data
        final visitDataList = <Map<String, dynamic>>[];
        final resourceDataList = <Map<String, dynamic>>[];
        final hospitalIds = <int>{};
        final departmentIds = <int>{};
        final doctorIds = <int>{};

        for (final visit in visits) {
          // Collect IDs for related data
          if (visit.hospitalId != null) hospitalIds.add(visit.hospitalId!);
          if (visit.departmentId != null)
            departmentIds.add(visit.departmentId!);
          if (visit.doctorId != null) doctorIds.add(visit.doctorId!);

          // Fetch resources for this visit
          final resources = await _database.getResourcesByVisit(visit.id);

          for (final resource in resources) {
            // Copy resource file to temp directory
            try {
              final sourceFile = await _storageService.getResourceFile(
                resource.filePath,
              );
              if (await sourceFile.exists()) {
                final fileName = p.basename(resource.filePath);
                final destFile = File('${resourcesDir.path}/$fileName');
                await sourceFile.copy(destFile.path);

                resourceDataList.add(resource.toJson());
              } else {
                AppLogger().w('Resource file not found: ${resource.filePath}');
              }
            } catch (e) {
              AppLogger().e('Error copying resource ${resource.id}: $e');
            }
          }

          visitDataList.add(visit.toJson());
        }

        // Fetch related hospital, department, doctor data
        Hospital? hospital;
        Department? department;
        Doctor? doctor;

        if (hospitalIds.isNotEmpty) {
          hospital = await _database.getHospitalById(hospitalIds.first);
        }
        if (departmentIds.isNotEmpty) {
          department = await _database.getDepartmentById(departmentIds.first);
        }
        if (doctorIds.isNotEmpty) {
          doctor = await _database.getDoctorById(doctorIds.first);
        }

        // Create export data for this treatment
        // Convert to JSON with proper datetime serialization
        exportData.add({
          'treatment': _treatmentToJson(treatment),
          'visits': visitDataList.map((v) => _visitToJson(v)).toList(),
          'resources': resourceDataList.map((r) => _resourceToJson(r)).toList(),
          'hospital': hospital != null ? _hospitalToJson(hospital) : null,
          'department': department != null
              ? _departmentToJson(department)
              : null,
          'doctor': doctor != null ? _doctorToJson(doctor) : null,
        });
      }

      // Create manifest.json
      final manifest = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'treatments': exportData,
      };

      final manifestFile = File('${exportDir.path}/manifest.json');
      await manifestFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(manifest),
      );

      AppLogger().d('Manifest created with ${exportData.length} treatments');

      // Create zip file
      final zipFilePath =
          '${tempDir.path}/medical_records_export_${DateTime.now().millisecondsSinceEpoch}.zip';

      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);

      // Add manifest.json at root level
      encoder.addFile(manifestFile, 'manifest.json');

      // Add resources directory if it contains files
      final resourceFiles = await resourcesDir.list().toList();
      if (resourceFiles.isNotEmpty) {
        for (final entity in resourceFiles) {
          if (entity is File) {
            final fileName = p.basename(entity.path);
            encoder.addFile(entity, 'resources/$fileName');
          }
        }
      }

      encoder.close();

      AppLogger().i(
        'Export completed: $zipFilePath (${exportData.length} treatments)',
      );

      // Clean up temp export directory
      await exportDir.delete(recursive: true);

      return File(zipFilePath);
    } catch (e, stackTrace) {
      AppLogger().e('Export failed: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Export all treatments within a date range
  ///
  /// [startDate] - Start of date range (inclusive)
  /// [endDate] - End of date range (inclusive)
  Future<File> exportTreatmentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allTreatments = await _database.getAllTreatments();

    final treatmentsInRange = allTreatments.where((treatment) {
      return treatment.startDate.isAfter(
            startDate.subtract(const Duration(days: 1)),
          ) &&
          treatment.startDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final treatmentIds = treatmentsInRange.map((t) => t.id).toList();
    return exportTreatments(treatmentIds);
  }

  /// Export all treatments
  Future<File> exportAllTreatments() async {
    final allTreatments = await _database.getAllTreatments();
    final treatmentIds = allTreatments.map((t) => t.id).toList();
    return exportTreatments(treatmentIds);
  }

  // JSON serialization helpers with proper datetime handling

  Map<String, dynamic> _treatmentToJson(Treatment treatment) {
    return {
      'id': treatment.id,
      'title': treatment.title,
      'diagnosis': treatment.diagnosis,
      'startDate': treatment.startDate.toIso8601String(),
      'endDate': treatment.endDate?.toIso8601String(),
      'createdAt': treatment.createdAt.toIso8601String(),
      'updatedAt': treatment.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _visitToJson(Map<String, dynamic> visitJson) {
    // visitJson is already from visit.toJson(), need to convert date fields
    return {
      'id': visitJson['id'],
      'category': visitJson['category'],
      'date': visitJson['date'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              visitJson['date'] as int,
            ).toIso8601String()
          : visitJson['date'],
      'details': visitJson['details'],
      'hospitalId': visitJson['hospitalId'],
      'departmentId': visitJson['departmentId'],
      'doctorId': visitJson['doctorId'],
      'informations': visitJson['informations'],
      'createdAt': visitJson['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              visitJson['createdAt'] as int,
            ).toIso8601String()
          : visitJson['createdAt'],
      'updatedAt': visitJson['updatedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              visitJson['updatedAt'] as int,
            ).toIso8601String()
          : visitJson['updatedAt'],
    };
  }

  Map<String, dynamic> _resourceToJson(Map<String, dynamic> resourceJson) {
    return {
      'id': resourceJson['id'],
      'type': resourceJson['type'],
      'filePath': resourceJson['filePath'],
      'notes': resourceJson['notes'],
      'createdAt': resourceJson['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              resourceJson['createdAt'] as int,
            ).toIso8601String()
          : resourceJson['createdAt'],
      'updatedAt': resourceJson['updatedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              resourceJson['updatedAt'] as int,
            ).toIso8601String()
          : resourceJson['updatedAt'],
    };
  }

  Map<String, dynamic> _hospitalToJson(Hospital hospital) {
    return {
      'id': hospital.id,
      'name': hospital.name,
      'address': hospital.address,
      'type': hospital.type,
      'level': hospital.level,
      'departmentIds': hospital.departmentIds,
    };
  }

  Map<String, dynamic> _departmentToJson(Department department) {
    return {
      'id': department.id,
      'name': department.name,
      'category': department.category,
    };
  }

  Map<String, dynamic> _doctorToJson(Doctor doctor) {
    return {
      'id': doctor.id,
      'name': doctor.name,
      'hospitalId': doctor.hospitalId,
      'departmentId': doctor.departmentId,
      'level': doctor.level,
    };
  }
}
