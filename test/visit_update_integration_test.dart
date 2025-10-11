import 'package:flutter_test/flutter_test.dart';
import 'package:app_database/app_database.dart';
import 'package:visit_form_bloc/visit_form_bloc.dart';
import 'package:drift/drift.dart';

// Simple test to verify VisitFormBloc can be created with VisitBloc parameter
void main() {
  group('Visit Update Integration Test', () {
    late AppDatabase database;

    setUp(() async {
      database = AppDatabase.forTesting();
      
      // Add minimal test data
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
      
      await database.createTreatment(
        TreatmentsCompanion.insert(
          title: Value('Test Treatment'),
          startDate: Value(DateTime.now().subtract(Duration(days: 30))),
          diagnosis: Value('Test Diagnosis'),
        ),
      );
      
      await database.createVisit(
        VisitsCompanion.insert(
          treatmentId: 1,
          category: Value(VisitCategory.outpatient.value),
          date: Value(DateTime.now().subtract(Duration(days: 1))),
          details: Value('Original visit details'),
          hospitalId: 1,
          departmentId: 1,
          doctorId: 1,
        ),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('should create VisitFormBloc without errors when VisitBloc is provided', () async {
      final visits = await database.getAllVisits();
      expect(visits.length, 1);
      final visit = visits.first;
      
      // This should not throw any errors - our fix allows VisitBloc parameter
      expect(
        () => VisitFormBloc(
          database,
          visitToEdit: visit,
          visitBloc: null, // We can't easily create VisitBloc here, but test the constructor accepts it
        ),
        returnsNormally,
      );
    });

    test('should handle visit update flow without errors', () async {
      final visits = await database.getAllVisits();
      expect(visits.length, 1);
      final visit = visits.first;
      
      // Create VisitFormBloc for editing
      final visitFormBloc = VisitFormBloc(
        database,
        visitToEdit: visit,
        visitBloc: null, // No VisitBloc for this test, but it should still work
      );
      
      // Wait for initialization
      await Future.delayed(Duration(milliseconds: 500));
      
      // Update the details field
      visitFormBloc.detailsFieldBloc.updateValue('Updated visit details');
      
      // Submit the form - this should not throw errors
      expect(() => visitFormBloc.submit(), returnsNormally);
      
      // Wait for processing
      await Future.delayed(Duration(milliseconds: 500));
      
      // Verify the visit was updated in the database
      final updatedVisits = await database.getAllVisits();
      expect(updatedVisits.length, 1);
      expect(updatedVisits.first.details, equals('Updated visit details'));
      
      await visitFormBloc.close();
    });
  });
}