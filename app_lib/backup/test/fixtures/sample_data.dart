import 'package:app_database/app_database.dart';
import 'package:drift/drift.dart';

/// Sample test data for medical records testing
class SampleData {
  // Sample Hospitals
  static HospitalsCompanion sampleHospital1() => HospitalsCompanion.insert(
        name: 'Central City Hospital',
        address: const Value('123 Medical Drive, City, State 12345'),
        type: const Value('General Hospital'),
        level: const Value('Class A Grade 3'),
        departmentIds: '[1,2]',
      );

  static HospitalsCompanion sampleHospital2() => HospitalsCompanion.insert(
        name: 'Specialty Care Clinic',
        address: const Value('456 Care Street, City, State 12345'),
        type: const Value('Specialty Hospital'),
        level: const Value('Class B Grade 2'),
        departmentIds: '[3]',
      );

  static HospitalsCompanion hospitalWithNulls() => HospitalsCompanion.insert(
        name: 'Minimal Hospital',
        address: const Value(null),
        type: const Value(null),
        level: const Value(null),
        departmentIds: '[]',
      );

  // Sample Departments
  static DepartmentsCompanion sampleDepartment1() =>
      DepartmentsCompanion.insert(
        name: 'Cardiology',
        category: const Value('Internal Medicine'),
      );

  static DepartmentsCompanion sampleDepartment2() =>
      DepartmentsCompanion.insert(
        name: 'Orthopedics',
        category: const Value('Surgery'),
      );

  static DepartmentsCompanion sampleDepartment3() =>
      DepartmentsCompanion.insert(
        name: 'Emergency',
        category: const Value('Emergency Services'),
      );

  // Sample Doctors
  static DoctorsCompanion sampleDoctor1(int hospitalId, int departmentId) =>
      DoctorsCompanion.insert(
        name: 'Dr. John Smith',
        hospitalId: hospitalId,
        departmentId: departmentId,
        level: const Value('Chief Physician'),
      );

  static DoctorsCompanion sampleDoctor2(int hospitalId, int departmentId) =>
      DoctorsCompanion.insert(
        name: 'Dr. Sarah Johnson',
        hospitalId: hospitalId,
        departmentId: departmentId,
        level: const Value('Attending Physician'),
      );

  // Sample Treatments
  static TreatmentsCompanion sampleTreatment1() => TreatmentsCompanion.insert(
        title: 'Heart Disease Treatment',
        diagnosis: 'Diagnosed with coronary artery disease',
        startDate: DateTime(2024, 1, 15),
        endDate: Value(DateTime(2024, 6, 15)),
      );

  static TreatmentsCompanion sampleTreatment2() => TreatmentsCompanion.insert(
        title: 'Physical Therapy',
        diagnosis: 'Post-surgical rehabilitation for knee replacement',
        startDate: DateTime(2024, 3, 1),
        endDate: const Value(null), // Ongoing treatment
      );

  static TreatmentsCompanion treatmentWithMinimalInfo() =>
      TreatmentsCompanion.insert(
        title: 'T',
        diagnosis: 'D',
        startDate: DateTime(2024, 1, 1),
        endDate: const Value(null),
      );

  static TreatmentsCompanion treatmentInDateRange(
    DateTime start,
    DateTime? end,
  ) =>
      TreatmentsCompanion.insert(
        title: 'Treatment in Range',
        diagnosis: 'Testing date range',
        startDate: start,
        endDate: Value(end),
      );

  // Sample Visits
  static VisitsCompanion sampleVisit1({
    required int treatmentId,
    int? hospitalId,
    int? departmentId,
    int? doctorId,
  }) =>
      VisitsCompanion.insert(
        treatmentId: treatmentId,
        category: 'outpatient',
        date: DateTime(2024, 1, 20),
        details: 'Initial consultation and examination',
        hospitalId: Value(hospitalId),
        departmentId: Value(departmentId),
        doctorId: Value(doctorId),
        informations: const Value('{"bloodPressure": "120/80", "notes": "Patient doing well"}'),
      );

  static VisitsCompanion sampleVisit2({
    required int treatmentId,
    int? hospitalId,
    int? departmentId,
    int? doctorId,
  }) =>
      VisitsCompanion.insert(
        treatmentId: treatmentId,
        category: 'inpatient',
        date: DateTime(2024, 2, 15),
        details: 'Follow-up examination and medication adjustment',
        hospitalId: Value(hospitalId),
        departmentId: Value(departmentId),
        doctorId: Value(doctorId),
        informations: const Value(null),
      );

  static VisitsCompanion visitWithNulls({required int treatmentId}) =>
      VisitsCompanion.insert(
        treatmentId: treatmentId,
        category: 'outpatient',
        date: DateTime(2024, 1, 1),
        details: '',
        hospitalId: const Value(null),
        departmentId: const Value(null),
        doctorId: const Value(null),
        informations: const Value(null),
      );

  // Sample Resources
  static ResourcesCompanion sampleResource1({required int visitId}) =>
      ResourcesCompanion.insert(
        visitId: visitId,
        type: 'image',
        filePath: 'resources/$visitId/abc123.jpg',
        notes: const Value('X-ray scan of chest'),
      );

  static ResourcesCompanion sampleResource2({required int visitId}) =>
      ResourcesCompanion.insert(
        visitId: visitId,
        type: 'pdf',
        filePath: 'resources/$visitId/def456.pdf',
        notes: const Value('Lab test results'),
      );

  static ResourcesCompanion resourceWithNulls({required int visitId}) =>
      ResourcesCompanion.insert(
        visitId: visitId,
        type: 'image',
        filePath: 'resources/$visitId/minimal.jpg',
        notes: const Value(null),
      );
}

/// Helper to create a complete treatment hierarchy for testing
class CompleteDataFixture {
  final Hospital hospital;
  final Department department;
  final Doctor doctor;
  final Treatment treatment;
  final List<Visit> visits;
  final List<Resource> resources;

  CompleteDataFixture({
    required this.hospital,
    required this.department,
    required this.doctor,
    required this.treatment,
    required this.visits,
    required this.resources,
  });

  static int _counter = 0;

  /// Creates a complete data hierarchy in the test database with unique names
  static Future<CompleteDataFixture> create(AppDatabase db) async {
    final uniqueId = _counter++;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Create hospital with unique name
    final hospitalId = await db.createHospital(
      HospitalsCompanion.insert(
        name: 'Central City Hospital $uniqueId-$timestamp',
        address: const Value('123 Medical Drive, City, State 12345'),
        type: const Value('General Hospital'),
        level: const Value('Class A Grade 3'),
        departmentIds: '[1,2]',
      ),
    );
    final hospital = await db.getHospitalById(hospitalId);

    // Create department with unique name
    final departmentId = await db.createDepartment(
      DepartmentsCompanion.insert(
        name: 'Cardiology $uniqueId-$timestamp',
        category: const Value('Internal Medicine'),
      ),
    );
    final department = await db.getDepartmentById(departmentId);

    // Create doctor with unique name
    final doctorId = await db.createDoctor(
      DoctorsCompanion.insert(
        name: 'Dr. John Smith $uniqueId-$timestamp',
        hospitalId: hospitalId,
        departmentId: departmentId,
        level: const Value('Chief Physician'),
      ),
    );
    final doctor = await db.getDoctorById(doctorId);

    // Create treatment with unique title
    final treatmentId = await db.createTreatment(
      TreatmentsCompanion.insert(
        title: 'Heart Disease Treatment $uniqueId-$timestamp',
        diagnosis: 'Diagnosed with coronary artery disease',
        startDate: DateTime(2024, 1, 15),
        endDate: Value(DateTime(2024, 6, 15)),
      ),
    );
    final treatment = await db.getTreatmentById(treatmentId);

    // Create visits
    final visitId1 = await db.createVisit(
      SampleData.sampleVisit1(
        treatmentId: treatmentId,
        hospitalId: hospitalId,
        departmentId: departmentId,
        doctorId: doctorId,
      ),
    );
    final visitId2 = await db.createVisit(
      SampleData.sampleVisit2(
        treatmentId: treatmentId,
        hospitalId: hospitalId,
        departmentId: departmentId,
        doctorId: doctorId,
      ),
    );

    final visits = await db.getVisitsByTreatment(treatmentId);

    // Create resources
    await db.createResource(SampleData.sampleResource1(visitId: visitId1));
    await db.createResource(SampleData.sampleResource2(visitId: visitId2));

    final resources1 = await db.getResourcesByVisit(visitId1);
    final resources2 = await db.getResourcesByVisit(visitId2);
    final resources = [...resources1, ...resources2];

    return CompleteDataFixture(
      hospital: hospital!,
      department: department!,
      doctor: doctor!,
      treatment: treatment!,
      visits: visits,
      resources: resources,
    );
  }

  /// Resets the counter (useful between test groups)
  static void resetCounter() {
    _counter = 0;
  }

  /// Creates multiple complete treatment hierarchies
  static Future<List<CompleteDataFixture>> createMultiple(
    AppDatabase db,
    int count,
  ) async {
    final fixtures = <CompleteDataFixture>[];
    for (var i = 0; i < count; i++) {
      fixtures.add(await create(db));
    }
    return fixtures;
  }
}
