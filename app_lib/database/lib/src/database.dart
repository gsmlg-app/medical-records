import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'tables/tables.dart';
import 'enums.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Hospitals,
    Departments,
    Doctors,
    Treatments,
    Visits,
    Resources,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  // Add this factory for tests
  factory AppDatabase.forTesting() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'medical_records',
      native: const DriftNativeOptions(
        // By default, `driftDatabase` from `package:drift_flutter` stores the
        // database files in `getApplicationDocumentsDirectory()`.
        databaseDirectory: getApplicationSupportDirectory,
      ),
      // If you need web support, see https://drift.simonbinder.eu/platforms/web/
    );
  }

  // CRUD Methods for Hospitals
  Future<int> createHospital(HospitalsCompanion hospital) =>
      into(hospitals).insert(hospital);
  Future<List<Hospital>> getAllHospitals() => select(hospitals).get();
  Future<Hospital?> getHospitalById(int id) =>
      (select(hospitals)..where((h) => h.id.equals(id))).getSingleOrNull();
  Future<bool> updateHospital(Hospital hospital) =>
      update(hospitals).replace(hospital);
  Future<int> deleteHospital(int id) =>
      (delete(hospitals)..where((h) => h.id.equals(id))).go();

  // CRUD Methods for Departments
  Future<int> createDepartment(DepartmentsCompanion department) =>
      into(departments).insert(department);
  Future<List<Department>> getAllDepartments() => select(departments).get();
  Future<Department?> getDepartmentById(int id) =>
      (select(departments)..where((d) => d.id.equals(id))).getSingleOrNull();
  Future<bool> updateDepartment(Department department) =>
      update(departments).replace(department);
  Future<int> deleteDepartment(int id) =>
      (delete(departments)..where((d) => d.id.equals(id))).go();

  // CRUD Methods for Doctors
  Future<int> createDoctor(DoctorsCompanion doctor) =>
      into(doctors).insert(doctor);
  Future<List<Doctor>> getAllDoctors() => select(doctors).get();
  Future<Doctor?> getDoctorById(int id) =>
      (select(doctors)..where((d) => d.id.equals(id))).getSingleOrNull();
  Future<List<Doctor>> getDoctorsByHospital(int hospitalId) =>
      (select(doctors)..where((d) => d.hospitalId.equals(hospitalId))).get();
  Future<bool> updateDoctor(Doctor doctor) => update(doctors).replace(doctor);
  Future<int> deleteDoctor(int id) =>
      (delete(doctors)..where((d) => d.id.equals(id))).go();

  // CRUD Methods for Treatments
  Future<int> createTreatment(TreatmentsCompanion treatment) =>
      into(treatments).insert(treatment);
  Future<List<Treatment>> getAllTreatments() => select(treatments).get();
  Future<Treatment?> getTreatmentById(int id) =>
      (select(treatments)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<bool> updateTreatment(Treatment treatment) =>
      update(treatments).replace(treatment);
  Future<int> deleteTreatment(int id) =>
      (delete(treatments)..where((t) => t.id.equals(id))).go();

  // CRUD Methods for Visits
  Future<int> createVisit(VisitsCompanion visit) => into(visits).insert(visit);
  Future<List<Visit>> getAllVisits() => select(visits).get();
  Future<Visit?> getVisitById(int id) =>
      (select(visits)..where((v) => v.id.equals(id))).getSingleOrNull();
  Future<List<Visit>> getVisitsByTreatment(int treatmentId) =>
      (select(visits)..where((v) => v.treatmentId.equals(treatmentId))).get();
  Future<bool> updateVisit(Visit visit) => update(visits).replace(visit);
  Future<int> deleteVisit(int id) =>
      (delete(visits)..where((v) => v.id.equals(id))).go();

  // CRUD Methods for Resources
  Future<int> createResource(ResourcesCompanion resource) =>
      into(resources).insert(resource);
  Future<List<Resource>> getAllResources() => select(resources).get();
  Future<Resource?> getResourceById(int id) =>
      (select(resources)..where((r) => r.id.equals(id))).getSingleOrNull();
  Future<List<Resource>> getResourcesByVisit(int visitId) =>
      (select(resources)..where((r) => r.visitId.equals(visitId))).get();
  Future<bool> updateResource(Resource resource) =>
      update(resources).replace(resource);
  Future<int> deleteResource(int id) =>
      (delete(resources)..where((r) => r.id.equals(id))).go();
}
