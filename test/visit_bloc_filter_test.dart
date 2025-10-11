import 'package:flutter_test/flutter_test.dart';
import 'package:app_database/app_database.dart';
import 'package:visit/visit.dart';
import 'package:drift/drift.dart';

void main() {
  group('VisitBloc Filter Tests', () {
    late AppDatabase database;
    late VisitBloc visitBloc;

    setUp(() async {
      database = AppDatabase.forTesting();
      visitBloc = VisitBloc(database);
      
      // Add test data
      await database.createHospital(
        HospitalsCompanion.insert(
          name: 'Test Hospital',
          address: Value('Test Address'),
          type: Value('General'),
          level: Value('A'),
          departmentIds: '[]',
        ),
      );
      
      await database.createDepartment(
        DepartmentsCompanion.insert(
          name: 'Cardiology',
          category: Value('Medical'),
        ),
      );
      
      await database.createDoctor(
        DoctorsCompanion.insert(
          name: 'Dr. Smith',
          level: Value('Senior'),
          hospitalId: Value(1),
          departmentId: Value(1),
        ),
      );
      
      // Create two treatments
      await database.createTreatment(
        TreatmentsCompanion.insert(
          startDate: Value(DateTime.now().subtract(Duration(days: 30))),
          diagnosis: Value('Treatment 1 Diagnosis'),
        ),
      );
      
      await database.createTreatment(
        TreatmentsCompanion.insert(
          startDate: Value(DateTime.now().subtract(Duration(days: 30))),
          diagnosis: Value('Treatment 2 Diagnosis'),
        ),
      );
      
      // Create visits for both treatments
      await database.createVisit(
        VisitsCompanion.insert(
          treatmentId: 1,
          category: Value(VisitCategory.outpatient.value),
          date: Value(DateTime.now().subtract(Duration(days: 1))),
          details: 'Original visit for treatment 1',
          hospitalId: Value(1),
          departmentId: Value(1),
          doctorId: Value(1),
        ),
      );
      
      await database.createVisit(
        VisitsCompanion.insert(
          treatmentId: 2,
          category: Value(VisitCategory.outpatient.value),
          date: Value(DateTime.now().subtract(Duration(days: 1))),
          details: 'Original visit for treatment 2',
          hospitalId: Value(1),
          departmentId: Value(1),
          doctorId: Value(1),
        ),
      );
    });

    tearDown(() async {
      await visitBloc.close();
      await database.close();
    });

    test('should maintain treatment filter when updating a visit', () async {
      // Load visits for treatment 1
      visitBloc.add(LoadVisitsByTreatment(1));
      await Future.delayed(Duration(milliseconds: 500));
      
      expect(visitBloc.state, isA<VisitLoaded>());
      var initialState = visitBloc.state as VisitLoaded;
      expect(initialState.visits.length, 1);
      expect(initialState.visits.first.details, equals('Original visit for treatment 1'));
      
      // Update the visit
      final visitToUpdate = initialState.visits.first;
      visitBloc.add(UpdateVisit(
        id: visitToUpdate.id,
        treatmentId: visitToUpdate.treatmentId,
        category: visitToUpdate.category,
        date: visitToUpdate.date,
        details: 'Updated visit for treatment 1',
        hospitalId: visitToUpdate.hospitalId,
        departmentId: visitToUpdate.departmentId,
        doctorId: visitToUpdate.doctorId,
        informations: visitToUpdate.informations,
      ));
      
      // Wait for processing
      await Future.delayed(Duration(milliseconds: 500));
      
      // Verify the state is still filtered (only treatment 1 visits)
      expect(visitBloc.state, isA<VisitLoaded>());
      final updatedState = visitBloc.state as VisitLoaded;
      expect(updatedState.visits.length, 1);
      expect(updatedState.visits.first.details, equals('Updated visit for treatment 1'));
      expect(updatedState.visits.first.treatmentId, equals(1));
    });

    test('should maintain treatment filter when adding a visit', () async {
      // Load visits for treatment 1
      visitBloc.add(LoadVisitsByTreatment(1));
      await Future.delayed(Duration(milliseconds: 500));
      
      expect(visitBloc.state, isA<VisitLoaded>());
      var initialState = visitBloc.state as VisitLoaded;
      expect(initialState.visits.length, 1);
      
      // Add a new visit for treatment 1
      visitBloc.add(AddVisit(
        treatmentId: 1,
        category: VisitCategory.inpatient,
        date: DateTime.now(),
        details: 'New visit for treatment 1',
        hospitalId: 1,
        departmentId: 1,
        doctorId: 1,
      ));
      
      // Wait for processing
      await Future.delayed(Duration(milliseconds: 500));
      
      // Verify the state is still filtered (only treatment 1 visits)
      expect(visitBloc.state, isA<VisitLoaded>());
      final updatedState = visitBloc.state as VisitLoaded;
      expect(updatedState.visits.length, 2);
      expect(updatedState.visits.any((v) => v.details == 'New visit for treatment 1'), isTrue);
      expect(updatedState.visits.every((v) => v.treatmentId == 1), isTrue);
    });

    test('should maintain treatment filter when deleting a visit', () async {
      // Load visits for treatment 1
      visitBloc.add(LoadVisitsByTreatment(1));
      await Future.delayed(Duration(milliseconds: 500));
      
      expect(visitBloc.state, isA<VisitLoaded>());
      var initialState = visitBloc.state as VisitLoaded;
      expect(initialState.visits.length, 1);
      
      // Delete the visit
      final visitToDelete = initialState.visits.first;
      visitBloc.add(DeleteVisit(visitToDelete.id));
      
      // Wait for processing
      await Future.delayed(Duration(milliseconds: 500));
      
      // Verify the state is still filtered (no visits for treatment 1)
      expect(visitBloc.state, isA<VisitLoaded>());
      final updatedState = visitBloc.state as VisitLoaded;
      expect(updatedState.visits.length, 0);
    });

    test('should reset filter when loading all visits', () async {
      // Load visits for treatment 1
      visitBloc.add(LoadVisitsByTreatment(1));
      await Future.delayed(Duration(milliseconds: 500));
      
      expect(visitBloc.state, isA<VisitLoaded>());
      var filteredState = visitBloc.state as VisitLoaded;
      expect(filteredState.visits.length, 1);
      
      // Load all visits
      visitBloc.add(LoadVisits());
      await Future.delayed(Duration(milliseconds: 500));
      
      // Verify all visits are loaded
      expect(visitBloc.state, isA<VisitLoaded>());
      var allVisitsState = visitBloc.state as VisitLoaded;
      expect(allVisitsState.visits.length, 2);
    });
  });
}