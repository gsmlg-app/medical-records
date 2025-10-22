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
      final exportDir = Directory('${tempDir.path}/export_${DateTime.now().millisecondsSinceEpoch}');
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
          if (visit.departmentId != null) departmentIds.add(visit.departmentId!);
          if (visit.doctorId != null) doctorIds.add(visit.doctorId!);

          // Fetch resources for this visit
          final resources = await _database.getResourcesByVisit(visit.id);

          for (final resource in resources) {
            // Copy resource file to temp directory
            try {
              final sourceFile = await _storageService.getResourceFile(resource.filePath);
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
        exportData.add({
          'treatment': treatment.toJson(),
          'visits': visitDataList,
          'resources': resourceDataList,
          'hospital': hospital?.toJson(),
          'department': department?.toJson(),
          'doctor': doctor?.toJson(),
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
      final zipFilePath = '${tempDir.path}/medical_records_export_${DateTime.now().millisecondsSinceEpoch}.zip';

      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);
      encoder.addDirectory(exportDir);
      encoder.close();

      AppLogger().i('Export completed: $zipFilePath');

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
  Future<File> exportTreatmentsByDateRange(DateTime startDate, DateTime endDate) async {
    final allTreatments = await _database.getAllTreatments();

    final treatmentsInRange = allTreatments.where((treatment) {
      return treatment.startDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
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
}
