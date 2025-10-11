import 'package:flutter_test/flutter_test.dart';
import 'package:app_database/app_database.dart';
import 'package:visit_form_bloc/visit_form_bloc.dart';
import 'package:drift/drift.dart';

void main() {
  group('VisitFormBloc Integration Test', () {
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
          hospitalId: 1,
          departmentId: 1,
        ),
      );
      
      await database.createTreatment(
        TreatmentsCompanion.insert(
          title: 'Test Treatment',
          startDate: DateTime.now().subtract(Duration(days: 30)),
          diagnosis: 'Test Diagnosis',
        ),
      );
      
      await database.createVisit(
        VisitsCompanion.insert(
          treatmentId: 1,
          category: VisitCategory.outpatient.value,
          date: DateTime.now().subtract(Duration(days: 1)),
          details: 'Original visit details',
          hospitalId: Value(1),
          departmentId: Value(1),
          doctorId: Value(1),
        ),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('should create VisitFormBloc with VisitBloc parameter without errors', () async {
      final visits = await database.getAllVisits();
      expect(visits.length, 1);
      final visit = visits.first;
      
      // This should not throw any errors - our fix allows VisitBloc parameter
      expect(
        () => VisitFormBloc(
          database,
          visitToEdit: visit,
          visitBloc: null, // Test that constructor accepts the parameter
        ),
        returnsNormally,
      );
    });

    test('should handle visit update flow and update database', () async {
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
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Verify the visit was updated in the database
      final updatedVisits = await database.getAllVisits();
      expect(updatedVisits.length, 1);
      expect(updatedVisits.first.details, equals('Updated visit details'));
      
      await visitFormBloc.close();
    });

    test('should update visitToEdit reference when form is submitted', () async {
      final visits = await database.getAllVisits();
      expect(visits.length, 1);
      final originalVisit = visits.first;
      
      // Create VisitFormBloc for editing
      final visitFormBloc = VisitFormBloc(
        database,
        visitToEdit: originalVisit,
        visitBloc: null,
      );
      
      // Wait for initialization
      await Future.delayed(Duration(milliseconds: 500));
      
      // Update the details field
      visitFormBloc.detailsFieldBloc.updateValue('Updated visit details');
      
      // Submit the form
      visitFormBloc.submit();
      
      // Wait for processing
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Verify the visitToEdit reference was updated
      expect(visitFormBloc.visitToEdit?.details, equals('Updated visit details'));
      expect(visitFormBloc.visitToEdit?.id, equals(originalVisit.id));
      
      await visitFormBloc.close();
    });
  });
}