import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_locale/gen_l10n/app_localizations.dart';
import 'package:app_database/app_database.dart';
import 'package:visit_form_bloc/visit_form_bloc.dart';
import 'package:visit_form_widget/visit_form.dart';
import 'package:form_bloc/form_bloc.dart';
import 'package:drift/drift.dart';

void main() {
  group('VisitFormBloc Dropdown Tests', () {
    late AppDatabase database;

    setUp(() async {
      // Create an in-memory database for testing
      database = AppDatabase.forTesting();
      
      // Add test data
      await database.createHospital(
        HospitalsCompanion.insert(
          name: 'Test Hospital 1',
          address: const Value('Address 1'),
          type: const Value('General'),
          level: const Value('A'),
          departmentIds: '[]', // JSON encoded empty list
        ),
      );
      
      await database.createDepartment(
        DepartmentsCompanion.insert(
          name: 'Cardiology',
          category: const Value('Medical'),
        ),
      );
      
      await database.createDoctor(
        DoctorsCompanion.insert(
          name: 'Dr. Smith',
          level: const Value('Senior'),
          hospitalId: 1,
          departmentId: 1,
        ),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('should initialize without dropdown assertion errors (add visit)', () async {
      // Create VisitFormBloc for ADD visit (no visitToEdit parameter)
      // This should not throw any dropdown assertion errors
      expect(
        () => VisitFormBloc(database),
        returnsNormally,
      );
    });

    test('should initialize without dropdown assertion errors (edit visit)', () async {
      // Create a test visit
      final testVisit = Visit(
        id: 1,
        treatmentId: 1,
        category: VisitCategory.outpatient.value,
        date: DateTime.now(),
        details: 'Test visit details',
        hospitalId: 1,
        departmentId: 1,
        doctorId: 1,
        informations: 'Test info',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // This should not throw any dropdown assertion errors
      expect(
        () => VisitFormBloc(database, visitToEdit: testVisit),
        returnsNormally,
      );
    });

    test('should load form data and populate dropdowns correctly', () async {
      final testVisit = Visit(
        id: 1,
        treatmentId: 1,
        category: VisitCategory.outpatient.value,
        date: DateTime.now(),
        details: 'Test visit details',
        hospitalId: 1,
        departmentId: 1,
        doctorId: 1,
        informations: 'Test info',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final visitFormBloc = VisitFormBloc(database, visitToEdit: testVisit);
      
      // Wait for initialization
      await Future.delayed(Duration(seconds: 2));
      
      // Check that the form loaded successfully
      expect(visitFormBloc.state, isA<FormBlocState>());
      
      // Check that values are set correctly (items are private, so we check values)
      expect(visitFormBloc.hospitalFieldBloc.value, equals(1));
      expect(visitFormBloc.departmentFieldBloc.value, equals(1));
      expect(visitFormBloc.doctorFieldBloc.value, equals(1));
      
      await visitFormBloc.close();
    });

    testWidgets('should render Add Visit form without dropdown assertion errors', (WidgetTester tester) async {
      // Create VisitFormBloc for ADD visit (no visitToEdit parameter)
      final bloc = VisitFormBloc(database);
      
      // Build widget with VisitForm and proper localization
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          home: BlocProvider<VisitFormBloc>(
            create: (context) => bloc,
            child: Scaffold(
              body: VisitForm(
                onSave: ({
                  required VisitCategory category,
                  required DateTime date,
                  required String details,
                  int? hospitalId,
                  int? departmentId,
                  int? doctorId,
                  String? informations,
                }) async {},
              ),
            ),
          ),
        ),
      );
      
      // Wait for initial render and async initialization
      await tester.pump();
      await tester.pumpAndSettle();
      
      // Verify no assertion errors occurred and form is displayed
      expect(find.byType(VisitForm), findsOneWidget);
      
      // The key test: if we got here without assertion errors, the fix worked!
      // We don't need to test the full functionality, just that the form renders
      
      await bloc.close();
    });
  });
}