import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:matcher/matcher.dart' as m;
import '../lib/src/database.dart';
import '../lib/src/enums.dart';

void main() {
  group('Medical Records Database Tests', () {
    late AppDatabase database;

    setUp(() {
      // Use in-memory database for testing
      database = AppDatabase.forTesting();
    });

    tearDown(() async {
      await database.close();
    });

    group('Hospitals Table Tests', () {
      test('should create and retrieve a hospital', () async {
        // Arrange
        final hospital = HospitalsCompanion.insert(
          name: 'General Hospital',
          address: Value('123 Main St'),
          type: Value('General Hospital'),
          level: Value('Class A Grade 3'),
          departmentIds: [1, 2, 3],
        );

        // Act
        final id = await database.createHospital(hospital);
        final retrievedHospital = await database.getHospitalById(id);

        // Assert
        expect(retrievedHospital, m.isNotNull);
        expect(retrievedHospital!.name, equals('General Hospital'));
        expect(retrievedHospital.address, equals('123 Main St'));
        expect(retrievedHospital.departmentIds, equals([1, 2, 3]));
      });

      test('should update a hospital', () async {
        // Arrange
        final hospital = HospitalsCompanion.insert(
          name: 'Test Hospital',
          address: Value('123 Test St'),
          departmentIds: [],
        );
        final id = await database.createHospital(hospital);
        final retrievedHospital = await database.getHospitalById(id);

        // Act
        if (retrievedHospital == null) {
          fail('Hospital should not be null');
        }
        final updatedHospital = retrievedHospital.copyWith(
          name: 'Updated Hospital',
          address: Value('456 Updated St'),
        );
        final success = await database.updateHospital(updatedHospital);
        final retrievedUpdatedHospital = await database.getHospitalById(id);

        // Assert
        expect(success, isTrue);
        expect(retrievedUpdatedHospital!.name, equals('Updated Hospital'));
        expect(retrievedUpdatedHospital.address, equals('456 Updated St'));
      });

      test('should delete a hospital', () async {
        // Arrange
        final hospital = HospitalsCompanion.insert(
          name: 'Hospital to Delete',
        );
        final id = await database.createHospital(hospital);

        // Act
        final deletedCount = await database.deleteHospital(id);
        final retrievedHospital = await database.getHospitalById(id);

        // Assert
        expect(deletedCount, equals(1));
        expect(retrievedHospital, m.isNull);
      });

      test('should get all hospitals', () async {
        // Arrange
        await database.createHospital(HospitalsCompanion.insert(name: 'Hospital 1', departmentIds: []));
        await database.createHospital(HospitalsCompanion.insert(name: 'Hospital 2', departmentIds: []));
        await database.createHospital(HospitalsCompanion.insert(name: 'Hospital 3', departmentIds: []));

        // Act
        final hospitals = await database.getAllHospitals();

        // Assert
        expect(hospitals.length, equals(3));
        expect(hospitals.map((h) => h.name), contains('Hospital 1'));
        expect(hospitals.map((h) => h.name), contains('Hospital 2'));
        expect(hospitals.map((h) => h.name), contains('Hospital 3'));
      });
    });

    group('Departments Table Tests', () {
      test('should create and retrieve a department', () async {
        // Arrange
        final department = DepartmentsCompanion.insert(
          name: 'Cardiology',
          category: 'Clinical Department',
        );

        // Act
        final id = await database.createDepartment(department);
        final retrievedDepartment = await database.getDepartmentById(id);

        // Assert
        expect(retrievedDepartment, m.isNotNull);
        expect(retrievedDepartment!.name, equals('Cardiology'));
        expect(retrievedDepartment.category, equals('Clinical Department'));
      });

      test('should enforce unique department names', () async {
        // Arrange
        final dept1 = DepartmentsCompanion.insert(name: 'Cardiology');
        final dept2 = DepartmentsCompanion.insert(name: 'Cardiology');

        // Act & Assert
        await database.createDepartment(dept1);
        expect(
          () => database.createDepartment(dept2),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Doctors Table Tests', () {
      test('should create and retrieve a doctor with relationships', () async {
        // Arrange
        final hospital = HospitalsCompanion.insert(name: 'Test Hospital');
        final hospitalId = await database.createHospital(hospital);

        final department = DepartmentsCompanion.insert(name: 'Cardiology');
        final departmentId = await database.createDepartment(department);

        final doctor = DoctorsCompanion.insert(
          hospitalId: hospitalId,
          departmentId: departmentId,
          name: 'Dr. John Doe',
          level: 'Attending Physician',
        );

        // Act
        final id = await database.createDoctor(doctor);
        final retrievedDoctor = await database.getDoctorById(id);

        // Assert
        expect(retrievedDoctor, m.isNotNull);
        expect(retrievedDoctor!.name, equals('Dr. John Doe'));
        expect(retrievedDoctor.hospitalId, equals(hospitalId));
        expect(retrievedDoctor.departmentId, equals(departmentId));
      });

      test('should get doctors by hospital', () async {
        // Arrange
        final hospital1 = HospitalsCompanion.insert(name: 'Hospital 1', departmentIds: []);
        final hospital1Id = await database.createHospital(hospital1);

        final hospital2 = HospitalsCompanion.insert(name: 'Hospital 2', departmentIds: []);
        final hospital2Id = await database.createHospital(hospital2);

        final department = DepartmentsCompanion.insert(name: 'Cardiology');
        final departmentId = await database.createDepartment(department);

        await database.createDoctor(DoctorsCompanion.insert(
          hospitalId: hospital1Id,
          departmentId: departmentId,
          name: 'Dr. Smith',
        ));

        await database.createDoctor(DoctorsCompanion.insert(
          hospitalId: hospital1Id,
          departmentId: departmentId,
          name: 'Dr. Johnson',
        ));

        await database.createDoctor(DoctorsCompanion.insert(
          hospitalId: hospital2Id,
          departmentId: departmentId,
          name: 'Dr. Williams',
        ));

        // Act
        final hospital1Doctors = await database.getDoctorsByHospital(hospital1Id);
        final hospital2Doctors = await database.getDoctorsByHospital(hospital2Id);

        // Assert
        expect(hospital1Doctors.length, equals(2));
        expect(hospital2Doctors.length, equals(1));
        expect(hospital1Doctors.map((d) => d.name), contains('Dr. Smith'));
        expect(hospital1Doctors.map((d) => d.name), contains('Dr. Johnson'));
        expect(hospital2Doctors.first.name, equals('Dr. Williams'));
      });
    });

    group('Treatments Table Tests', () {
      test('should create and retrieve a treatment', () async {
        // Arrange
        final now = DateTime.now();
        final treatment = TreatmentsCompanion.insert(
          title: 'Hypertension Treatment',
          diagnosis: 'Essential Hypertension',
          startDate: Value(now),
          endDate: Value(now.add(const Duration(days: 30))),
        );

        // Act
        final id = await database.createTreatment(treatment);
        final retrievedTreatment = await database.getTreatmentById(id);

        // Assert
        expect(retrievedTreatment, m.isNotNull);
        expect(retrievedTreatment!.title, equals('Hypertension Treatment'));
        expect(retrievedTreatment.diagnosis, equals('Essential Hypertension'));
        expect(retrievedTreatment.startDate, equals(now));
        expect(retrievedTreatment.endDate, equals(now.add(const Duration(days: 30))));
      });

      test('should handle ongoing treatments without end date', () async {
        // Arrange
        final now = DateTime.now();
        final treatment = TreatmentsCompanion.insert(
          title: 'Chronic Treatment',
          diagnosis: 'Chronic Condition',
          startDate: Value(now),
          endDate: const Value.absent(),
        );

        // Act
        final id = await database.createTreatment(treatment);
        final retrievedTreatment = await database.getTreatmentById(id);

        // Assert
        expect(retrievedTreatment, m.isNotNull);
        expect(retrievedTreatment!.endDate, m.isNull);
      });
    });

    group('Visits Table Tests', () {
      test('should create and retrieve a visit with enum category', () async {
        // Arrange
        final treatment = TreatmentsCompanion.insert(
          title: 'Test Treatment',
          diagnosis: 'Test Diagnosis',
          startDate: Value(DateTime.now()),
        );
        final treatmentId = await database.createTreatment(treatment);

        final hospital = HospitalsCompanion.insert(name: 'Test Hospital');
        final hospitalId = await database.createHospital(hospital);

        final department = DepartmentsCompanion.insert(name: 'Cardiology');
        final departmentId = await database.createDepartment(department);

        final doctor = DoctorsCompanion.insert(
          hospitalId: hospitalId,
          departmentId: departmentId,
          name: 'Dr. Test',
        );
        final doctorId = await database.createDoctor(doctor);

        final visit = VisitsCompanion.insert(
          treatmentId: treatmentId,
          category: const Value('outpatient'),
          date: Value(DateTime.now()),
          details: 'Regular checkup',
          hospitalId: Value(hospitalId),
          departmentId: Value(departmentId),
          doctorId: Value(doctorId),
          informations: Value({'notes': 'Patient feeling well', 'bloodPressure': '120/80'}),
        );

        // Act
        final id = await database.createVisit(visit);
        final retrievedVisit = await database.getVisitById(id);

        // Assert
        expect(retrievedVisit, m.isNotNull);
        expect(retrievedVisit!.treatmentId, equals(treatmentId));
        expect(retrievedVisit.category.value, equals('outpatient'));
        expect(retrievedVisit.details, equals('Regular checkup'));
        expect(retrievedVisit.hospitalId, equals(hospitalId));
        expect(retrievedVisit.departmentId, equals(departmentId));
        expect(retrievedVisit.doctorId, equals(doctorId));
        expect(retrievedVisit.informations['notes'], equals('Patient feeling well'));
        expect(retrievedVisit.informations['bloodPressure'], equals('120/80'));
      });

      test('should get visits by treatment', () async {
        // Arrange
        final treatment1 = TreatmentsCompanion.insert(
          title: 'Treatment 1',
          diagnosis: 'Diagnosis 1',
          startDate: Value(DateTime.now()),
        );
        final treatment1Id = await database.createTreatment(treatment1);

        final treatment2 = TreatmentsCompanion.insert(
          title: 'Treatment 2',
          diagnosis: 'Diagnosis 2',
          startDate: Value(DateTime.now()),
        );
        final treatment2Id = await database.createTreatment(treatment2);

        await database.createVisit(VisitsCompanion.insert(
          treatmentId: treatment1Id,
          category: const Value('outpatient'),
          date: Value(DateTime.now()),
          details: 'Visit 1',
        ));

        await database.createVisit(VisitsCompanion.insert(
          treatmentId: treatment1Id,
          category: const Value('inpatient'),
          date: Value(DateTime.now()),
          details: 'Visit 2',
        ));

        await database.createVisit(VisitsCompanion.insert(
          treatmentId: treatment2Id,
          category: const Value('outpatient'),
          date: Value(DateTime.now()),
          details: 'Visit 3',
        ));

        // Act
        final treatment1Visits = await database.getVisitsByTreatment(treatment1Id);
        final treatment2Visits = await database.getVisitsByTreatment(treatment2Id);

        // Assert
        expect(treatment1Visits.length, equals(2));
        expect(treatment2Visits.length, equals(1));
        expect(treatment1Visits.map((v) => v.details), contains('Visit 1'));
        expect(treatment1Visits.map((v) => v.details), contains('Visit 2'));
        expect(treatment2Visits.first.details, equals('Visit 3'));
      });
    });

    group('Resources Table Tests', () {
      test('should create and retrieve a resource with enum type', () async {
        // Arrange
        final treatment = TreatmentsCompanion.insert(
          title: 'Test Treatment',
          diagnosis: 'Test Diagnosis',
          startDate: Value(DateTime.now()),
        );
        final treatmentId = await database.createTreatment(treatment);

        final visit = VisitsCompanion.insert(
          treatmentId: treatmentId,
          category: const Value('outpatient'),
          date: Value(DateTime.now()),
          details: 'Test Visit',
        );
        final visitId = await database.createVisit(visit);

        final resource = ResourcesCompanion.insert(
          visitId: visitId,
          type: const Value('image'),
          filePath: '/storage/path/to/image.jpg',
          notes: Value('X-ray image'),
        );

        // Act
        final id = await database.createResource(resource);
        final retrievedResource = await database.getResourceById(id);

        // Assert
        expect(retrievedResource, m.isNotNull);
        expect(retrievedResource!.visitId, equals(visitId));
        expect(retrievedResource.type.value, equals('image'));
        expect(retrievedResource.filePath, equals('/storage/path/to/image.jpg'));
        expect(retrievedResource.notes, equals('X-ray image'));
      });

      test('should get resources by visit', () async {
        // Arrange
        final treatment = TreatmentsCompanion.insert(
          title: 'Test Treatment',
          diagnosis: 'Test Diagnosis',
          startDate: Value(DateTime.now()),
        );
        final treatmentId = await database.createTreatment(treatment);

        final visit1 = VisitsCompanion.insert(
          treatmentId: treatmentId,
          category: const Value('outpatient'),
          date: Value(DateTime.now()),
          details: 'Visit 1',
        );
        final visit1Id = await database.createVisit(visit1);

        final visit2 = VisitsCompanion.insert(
          treatmentId: treatmentId,
          category: const Value('outpatient'),
          date: Value(DateTime.now()),
          details: 'Visit 2',
        );
        final visit2Id = await database.createVisit(visit2);

        await database.createResource(ResourcesCompanion.insert(
          visitId: visit1Id,
          type: const Value('image'),
          filePath: '/storage/path1.jpg',
        ));

        await database.createResource(ResourcesCompanion.insert(
          visitId: visit1Id,
          type: const Value('document'),
          filePath: '/storage/path2.pdf',
        ));

        await database.createResource(ResourcesCompanion.insert(
          visitId: visit2Id,
          type: const Value('video'),
          filePath: '/storage/path3.mp4',
        ));

        // Act
        final visit1Resources = await database.getResourcesByVisit(visit1Id);
        final visit2Resources = await database.getResourcesByVisit(visit2Id);

        // Assert
        expect(visit1Resources.length, equals(2));
        expect(visit2Resources.length, equals(1));
        expect(visit1Resources.map((r) => r.type.value), contains('image'));
        expect(visit1Resources.map((r) => r.type.value), contains('document'));
        expect(visit2Resources.first.type.value, equals('video'));
      });
    });

    group('Type Converter Tests', () {
      test('should handle JSON conversion for department IDs', () async {
        // Arrange
        final departmentIds = [1, 5, 10, 15];
        final hospital = HospitalsCompanion.insert(
          name: 'Test Hospital',
          departmentIds: departmentIds,
        );

        // Act
        final id = await database.createHospital(hospital);
        final retrievedHospital = await database.getHospitalById(id);

        // Assert
        expect(retrievedHospital, m.isNotNull);
        expect(retrievedHospital!.departmentIds, equals(departmentIds));
        expect(retrievedHospital.departmentIds, isA<List<int>>());
      });

      test('should handle JSON conversion for informations field', () async {
        // Arrange
        final informations = {
          'bloodPressure': '120/80',
          'heartRate': '72',
          'temperature': '98.6',
          'notes': 'Patient feeling well',
        };

        final treatment = TreatmentsCompanion.insert(
          title: 'Test Treatment',
          diagnosis: 'Test Diagnosis',
          startDate: Value(DateTime.now()),
        );
        final treatmentId = await database.createTreatment(treatment);

        final visit = VisitsCompanion.insert(
          treatmentId: treatmentId,
          category: const Value('outpatient'),
          date: Value(DateTime.now()),
          details: 'Test Visit',
          informations: Value(informations),
        );

        // Act
        final id = await database.createVisit(visit);
        final retrievedVisit = await database.getVisitById(id);

        // Assert
        expect(retrievedVisit, m.isNotNull);
        expect(retrievedVisit!.informations, equals(informations));
        expect(retrievedVisit.informations, isA<Map<String, dynamic>>());
        expect(retrievedVisit.informations['bloodPressure'], equals('120/80'));
        expect(retrievedVisit.informations['heartRate'], equals('72'));
      });

      test('should handle empty and null JSON data', () async {
        // Arrange
        final treatment = TreatmentsCompanion.insert(
          title: 'Test Treatment',
          diagnosis: 'Test Diagnosis',
          startDate: Value(DateTime.now()),
        );
        final treatmentId = await database.createTreatment(treatment);

        final visit = VisitsCompanion.insert(
          treatmentId: treatmentId,
          category: const Value('outpatient'),
          date: Value(DateTime.now()),
          details: 'Test Visit',
          informations: const Value.absent(),
        );

        // Act
        final id = await database.createVisit(visit);
        final retrievedVisit = await database.getVisitById(id);

        // Assert
        expect(retrievedVisit, m.isNotNull);
        expect(retrievedVisit!.informations, equals({}));
      });
    });
  });
}
