import 'package:flutter_test/flutter_test.dart';
import 'package:app_database/app_database.dart';
import 'package:visit_form_bloc/visit_form_bloc.dart';
import 'package:visit/visit.dart';
import 'package:drift/drift.dart';

void main() {
  group('Visit Update Integration Test', () {
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
      
      await database.createTreatment(
        TreatmentsCompanion.insert(
          startDate: Value(DateTime.now().subtract(Duration(days: 30))),
          diagnosis: Value('Test Diagnosis'),
          status: Value('active'),
        ),
      );
      
      await database.createVisit(
        VisitsCompanion.insert(
          treatmentId: Value(1),
          category: Value(VisitCategory.outpatient.value),
          date: Value(DateTime.now().subtract(Duration(days: 1))),
          details: Value('Original visit details'),
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

    test('should create VisitFormBloc with VisitBloc without errors', () async {
      final visits = await database.getAllVisits();
      expect(visits.length, 1);
      final visit = visits.first;
      
      // This should not throw any errors
      expect(
        () => VisitFormBloc(
          database,
          visitToEdit: visit,
          visitBloc: visitBloc,
        ),
        returnsNormally,
      );
    });

    test('should update visit through VisitBloc when VisitFormBloc submits', () async {
      // Load visits in VisitBloc
      visitBloc.add(LoadVisitsByTreatment(1));
      await Future.delayed(Duration(milliseconds: 500));
      
      expect(visitBloc.state, isA<VisitLoaded>());
      final initialState = visitBloc.state as VisitLoaded;
      expect(initialState.visits.length, 1);
      expect(initialState.visits.first.details, equals('Original visit details'));
      
      // Get the visit and create VisitFormBloc
      final visit = initialState.visits.first;
      final visitFormBloc = VisitFormBloc(
        database,
        visitToEdit: visit,
        visitBloc: visitBloc,
      );
      
      // Wait for initialization
      await Future.delayed(Duration(milliseconds: 500));
      
      // Update the details field
      visitFormBloc.detailsFieldBloc.updateValue('Updated visit details');
      
      // Submit the form
      visitFormBloc.submit();
      
      // Wait for processing
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Verify VisitBloc state is updated
      expect(visitBloc.state, isA<VisitLoaded>());
      final updatedState = visitBloc.state as VisitLoaded;
      expect(updatedState.visits.length, 1);
      expect(updatedState.visits.first.details, equals('Updated visit details'));
      
      await visitFormBloc.close();
    });
  });
}