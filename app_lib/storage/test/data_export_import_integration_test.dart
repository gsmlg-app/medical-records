import 'dart:io';
import 'package:app_database/app_database.dart';
import 'package:app_storage/app_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'fixtures/sample_data.dart';
import 'helpers/test_helpers.dart';

// Mock path provider for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    final tempDir = await Directory.systemTemp.createTemp('medical_records_test_');
    return tempDir.path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    final tempDir = await Directory.systemTemp.createTemp('medical_records_docs_');
    return tempDir.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final tempDir = await Directory.systemTemp.createTemp('medical_records_support_');
    return tempDir.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late DataExportService exportService;
  late DataImportService importService;
  late Directory tempDir;

  setUp(() async {
    // Set up mock path provider
    PathProviderPlatform.instance = MockPathProviderPlatform();

    // Create test database
    database = AppDatabase.forTesting();

    // Create services
    exportService = DataExportService(database);
    importService = DataImportService(database);

    // Create temp directory
    tempDir = await TestHelpers.createTempDirectory();
  });

  tearDown(() async {
    await database.close();
    await TestHelpers.cleanupTempDirectory(tempDir);
  });

  group('Export/Import Round-Trip Integration Tests', () {
    test('Complete treatment with all relationships should survive round-trip', () async {
      // ARRANGE: Create complete test data
      final fixture = await CompleteDataFixture.create(database);

      // Verify initial data exists
      expect(fixture.hospital.name, contains('Central City Hospital'));
      expect(fixture.department.name, contains('Cardiology'));
      expect(fixture.doctor.name, contains('Dr. John Smith'));
      expect(fixture.treatment.title, contains('Heart Disease Treatment'));
      expect(fixture.visits.length, 2);
      expect(fixture.resources.length, 2);

      // ACT: Export the treatment
      final exportFile = await exportService.exportTreatments([fixture.treatment.id]);
      expect(await exportFile.exists(), isTrue);

      // Delete all data from database
      await database.deleteTreatment(fixture.treatment.id);
      await database.deleteHospital(fixture.hospital.id);
      await database.deleteDepartment(fixture.department.id);
      await database.deleteDoctor(fixture.doctor.id);

      // Verify data is deleted
      final deletedTreatment = await database.getTreatmentById(fixture.treatment.id);
      expect(deletedTreatment, isNull);

      // Import the exported data
      final parsedData = await importService.parseZipFile(exportFile);
      final conflicts = await importService.checkConflicts(parsedData['manifest']);
      expect(conflicts.length, 0); // No conflicts since we deleted everything

      await importService.importTreatments(
        parsedData,
        {}, // No conflict resolutions needed
      );

      // ASSERT: Verify data integrity after round-trip
      final allTreatments = await database.getAllTreatments();
      expect(allTreatments.length, 1);

      final importedTreatment = allTreatments.first;
      expect(importedTreatment.title, fixture.treatment.title);
      expect(importedTreatment.diagnosis, fixture.treatment.diagnosis);
      expect(
        TestHelpers.datesEqual(importedTreatment.startDate, fixture.treatment.startDate),
        isTrue,
      );
      expect(
        TestHelpers.datesEqual(importedTreatment.endDate, fixture.treatment.endDate),
        isTrue,
      );

      // Verify visits
      final importedVisits = await database.getVisitsByTreatment(importedTreatment.id);
      expect(importedVisits.length, 2);

      // Verify visit details (not just IDs which will change)
      for (final visit in importedVisits) {
        expect(visit.category, isIn(['outpatient', 'inpatient']));
        expect(visit.details, isNotEmpty);
      }

      // Verify hospital (name may differ due to unique ID, but data should match)
      final importedHospitals = await database.getAllHospitals();
      expect(importedHospitals.length, 1);
      expect(importedHospitals.first.address, fixture.hospital.address);
      expect(importedHospitals.first.type, fixture.hospital.type);
      expect(importedHospitals.first.level, fixture.hospital.level);
      expect(importedHospitals.first.departmentIds, fixture.hospital.departmentIds);

      // Verify department
      final importedDepartments = await database.getAllDepartments();
      expect(importedDepartments.length, 1);
      expect(importedDepartments.first.category, fixture.department.category);

      // Verify doctor
      final importedDoctors = await database.getAllDoctors();
      expect(importedDoctors.length, 1);
      expect(importedDoctors.first.level, fixture.doctor.level);

      // Clean up export file
      await exportFile.delete();
    });

    test('Multiple treatments should maintain separation after round-trip', () async {
      // ARRANGE: Create two complete treatment hierarchies
      final fixture1 = await CompleteDataFixture.create(database);
      final fixture2 = await CompleteDataFixture.create(database);

      // ACT: Export both treatments
      final exportFile = await exportService.exportTreatments([
        fixture1.treatment.id,
        fixture2.treatment.id,
      ]);

      // Clear database
      await database.deleteTreatment(fixture1.treatment.id);
      await database.deleteTreatment(fixture2.treatment.id);

      // Import
      final parsedData = await importService.parseZipFile(exportFile);
      await importService.importTreatments(parsedData, {});

      // ASSERT: Verify both treatments imported
      final allTreatments = await database.getAllTreatments();
      expect(allTreatments.length, 2);

      // Verify each treatment has its own visits
      final visits1 = await database.getVisitsByTreatment(allTreatments[0].id);
      final visits2 = await database.getVisitsByTreatment(allTreatments[1].id);

      expect(visits1.length, 2);
      expect(visits2.length, 2);

      // Verify visit IDs don't overlap
      final visitIds1 = visits1.map((v) => v.id).toSet();
      final visitIds2 = visits2.map((v) => v.id).toSet();
      expect(visitIds1.intersection(visitIds2).isEmpty, isTrue);

      await exportFile.delete();
    });

    test('Treatment with null optional fields should preserve nulls', () async {
      // ARRANGE: Create treatment with null endDate
      final treatmentId = await database.createTreatment(
        SampleData.sampleTreatment2(), // Has null endDate
      );
      final treatment = await database.getTreatmentById(treatmentId);

      expect(treatment!.endDate, isNull);

      // ACT: Export and import
      final exportFile = await exportService.exportTreatments([treatmentId]);

      await database.deleteTreatment(treatmentId);

      final parsedData = await importService.parseZipFile(exportFile);
      await importService.importTreatments(parsedData, {});

      // ASSERT: Verify null is preserved
      final allTreatments = await database.getAllTreatments();
      expect(allTreatments.length, 1);
      expect(allTreatments.first.endDate, isNull);

      await exportFile.delete();
    });

    test('Visit with all optional fields null should survive round-trip', () async {
      // ARRANGE: Create treatment with minimal visit
      final treatmentId = await database.createTreatment(SampleData.sampleTreatment1());

      await database.createVisit(SampleData.visitWithNulls(treatmentId: treatmentId));

      // ACT: Export and import
      final exportFile = await exportService.exportTreatments([treatmentId]);

      await database.deleteTreatment(treatmentId);

      final parsedData = await importService.parseZipFile(exportFile);
      await importService.importTreatments(parsedData, {});

      // ASSERT: Verify null fields preserved
      final allTreatments = await database.getAllTreatments();
      final visits = await database.getVisitsByTreatment(allTreatments.first.id);

      expect(visits.length, 1);
      expect(visits.first.hospitalId, isNull);
      expect(visits.first.departmentId, isNull);
      expect(visits.first.doctorId, isNull);
      expect(visits.first.informations, isNull);

      await exportFile.delete();
    });

    test('Hospital departmentIds should be preserved during round-trip', () async {
      // ARRANGE: Create hospital with department IDs
      final hospitalId = await database.createHospital(SampleData.sampleHospital1());

      // Create treatment referencing this hospital
      final treatmentId = await database.createTreatment(SampleData.sampleTreatment1());
      await database.createVisit(SampleData.sampleVisit1(
        treatmentId: treatmentId,
        hospitalId: hospitalId,
      ));

      // Get original hospital data
      final originalHospital = await database.getHospitalById(hospitalId);
      expect(originalHospital, isNotNull);

      // ACT: Export and import
      final exportFile = await exportService.exportTreatments([treatmentId]);

      await database.deleteTreatment(treatmentId);
      await database.deleteHospital(hospitalId);

      final parsedData = await importService.parseZipFile(exportFile);
      await importService.importTreatments(parsedData, {});

      // ASSERT: Verify departmentIds preserved
      final importedHospitals = await database.getAllHospitals();
      expect(importedHospitals.length, 1);
      expect(importedHospitals.first.departmentIds, originalHospital!.departmentIds);

      await exportFile.delete();
    });

    test('Large dataset (10 treatments) should complete without errors', () async {
      // ARRANGE: Create 10 treatments
      final treatmentIds = <int>[];

      for (var i = 0; i < 10; i++) {
        final id = await database.createTreatment(
          TreatmentsCompanion.insert(
            title: 'Treatment $i',
            diagnosis: 'Diagnosis $i',
            startDate: DateTime(2024, 1, i + 1),
          ),
        );
        treatmentIds.add(id);

        // Add 2 visits per treatment
        await database.createVisit(SampleData.sampleVisit1(treatmentId: id));
        await database.createVisit(SampleData.sampleVisit2(treatmentId: id));
      }

      // ACT: Export all
      final exportFile = await exportService.exportTreatments(treatmentIds);

      // Delete all (must delete visits first, then treatments)
      for (final id in treatmentIds) {
        final visits = await database.getVisitsByTreatment(id);
        for (final visit in visits) {
          await database.deleteVisit(visit.id);
        }
        await database.deleteTreatment(id);
      }

      // Import all
      final parsedData = await importService.parseZipFile(exportFile);
      await importService.importTreatments(parsedData, {});

      // ASSERT: Verify all imported
      final allTreatments = await database.getAllTreatments();
      expect(allTreatments.length, 10);

      final allVisits = await database.getAllVisits();
      expect(allVisits.length, 20); // 2 visits per treatment

      await exportFile.delete();
    });

    test('Empty treatment list should create valid export with zero treatments', () async {
      // ACT: Export empty list
      final exportFile = await exportService.exportTreatments([]);

      // Verify file created
      expect(await exportFile.exists(), isTrue);

      // Verify can be parsed
      final parsedData = await importService.parseZipFile(exportFile);
      expect(parsedData['manifest']['treatments'], isEmpty);

      // Verify can be imported (no-op)
      await importService.importTreatments(parsedData, {});

      await exportFile.delete();
    });

    test('Exported ZIP file should have valid structure', () async {
      // ARRANGE
      final fixture = await CompleteDataFixture.create(database);

      // ACT
      final exportFile = await exportService.exportTreatments([fixture.treatment.id]);

      // ASSERT: Validate ZIP structure
      // Note: Not requiring resources directory since test fixtures don't create actual files
      final isValid = await TestHelpers.validateZipStructure(
        exportFile,
        requireManifest: true,
        requireResourcesDir: false,
      );
      expect(isValid, isTrue);

      // Verify manifest can be extracted
      final manifestJson = await TestHelpers.extractManifestFromZip(exportFile);
      expect(manifestJson, isNotNull);
      expect(manifestJson!.contains('"version"'), isTrue);
      expect(manifestJson.contains('"treatments"'), isTrue);

      await exportFile.delete();
    });
  });

  group('Conflict Resolution Tests', () {
    test('Skip resolution should not import conflicting treatment', () async {
      // ARRANGE: Create initial treatment
      final treatmentId = await database.createTreatment(SampleData.sampleTreatment1());
      final initialCount = (await database.getAllTreatments()).length;

      // ACT: Export
      final exportFile = await exportService.exportTreatments([treatmentId]);

      // Import with skip resolution
      final parsedData = await importService.parseZipFile(exportFile);
      final conflicts = await importService.checkConflicts(parsedData['manifest']);

      expect(conflicts.length, 1);

      await importService.importTreatments(
        parsedData,
        {conflicts.first.treatment.title: ConflictResolution.skip},
      );

      // ASSERT: No new treatment added
      final finalCount = (await database.getAllTreatments()).length;
      expect(finalCount, initialCount);

      await exportFile.delete();
    });

    test('Override resolution should replace existing treatment', () async {
      // ARRANGE: Create initial treatment and visit
      final treatmentId = await database.createTreatment(SampleData.sampleTreatment1());
      final visitId = await database.createVisit(
        SampleData.sampleVisit1(treatmentId: treatmentId),
      );

      final initialVisitCount = (await database.getAllVisits()).length;

      // ACT: Export
      final exportFile = await exportService.exportTreatments([treatmentId]);

      // Import with override resolution
      final parsedData = await importService.parseZipFile(exportFile);
      final conflicts = await importService.checkConflicts(parsedData['manifest']);

      await importService.importTreatments(
        parsedData,
        {conflicts.first.treatment.title: ConflictResolution.override},
      );

      // ASSERT: Still only one treatment, but new ID
      final allTreatments = await database.getAllTreatments();
      expect(allTreatments.length, 1);
      expect(allTreatments.first.id, isNot(treatmentId)); // New ID assigned

      // Visits should be recreated
      final allVisits = await database.getAllVisits();
      expect(allVisits.length, initialVisitCount); // Same count
      expect(allVisits.first.id, isNot(visitId)); // But new ID

      await exportFile.delete();
    });

    test('CreateNew resolution should create duplicate treatment', () async {
      // ARRANGE
      final treatmentId = await database.createTreatment(SampleData.sampleTreatment1());

      // ACT: Export
      final exportFile = await exportService.exportTreatments([treatmentId]);

      // Import with createNew resolution
      final parsedData = await importService.parseZipFile(exportFile);
      final conflicts = await importService.checkConflicts(parsedData['manifest']);

      await importService.importTreatments(
        parsedData,
        {conflicts.first.treatment.title: ConflictResolution.createNew},
      );

      // ASSERT: Should have two treatments with same title
      final allTreatments = await database.getAllTreatments();
      expect(allTreatments.length, 2);
      expect(allTreatments[0].title, allTreatments[1].title);
      expect(allTreatments[0].id, isNot(allTreatments[1].id));

      await exportFile.delete();
    });
  });
}
