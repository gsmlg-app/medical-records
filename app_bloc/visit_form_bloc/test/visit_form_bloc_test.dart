import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:visit_form_bloc/src/bloc.dart';
import 'package:app_database/app_database.dart';
import 'package:duskmoon_form/duskmoon_form.dart';

void main() {
  group('VisitFormBloc', () {
    late _MockAppDatabase mockDatabase;
    late _MockVisitFormBloc visitFormBloc;

    setUp(() {
      // Create mocks
      mockDatabase = _MockAppDatabase();
      visitFormBloc = _MockVisitFormBloc(mockDatabase);
    });

    tearDown(() {
      visitFormBloc.close();
    });

    test('initial state is FormBlocState', () {
      expect(visitFormBloc.state, isA<FormBlocState<String, String>>());
    });

    blocTest<VisitFormBloc, FormBlocState<String, String>>(
      'emits updated state when category field is updated',
      build: () => visitFormBloc,
      act: (bloc) {
        bloc.categoryFieldBloc.updateValue(VisitCategory.inpatient);
      },
      expect: () => [
        isA<FormBlocState<String, String>>().having(
          (s) => s.isValid(),
          'isValid',
          true, // Form is valid because category and date (required fields) have values
        ),
      ],
    );

    blocTest<VisitFormBloc, FormBlocState<String, String>>(
      'emits updated state when date field is updated',
      build: () => visitFormBloc,
      act: (bloc) {
        bloc.dateFieldBloc.updateValue(DateTime(2023, 1, 1));
      },
      expect: () => [
        isA<FormBlocState<String, String>>().having(
          (s) => s.isValid(),
          'isValid',
          true, // Form is valid because category and date (required fields) have values
        ),
      ],
    );

    blocTest<VisitFormBloc, FormBlocState<String, String>>(
      'emits updated state when details field is updated',
      build: () => visitFormBloc,
      act: (bloc) {
        bloc.detailsFieldBloc.updateValue('Test Details');
      },
      expect: () => [
        isA<FormBlocState<String, String>>().having(
          (s) => s.isValid(),
          'isValid',
          true, // Form is valid because category and date (required fields) have values
        ),
      ],
    );

    blocTest<VisitFormBloc, FormBlocState<String, String>>(
      'resets form to initial state',
      build: () => visitFormBloc,
      act: (bloc) {
        // First set some values
        bloc.categoryFieldBloc.updateValue(VisitCategory.inpatient);
        bloc.detailsFieldBloc.updateValue('Test Details');
        // Then reset
        bloc.resetForm();
      },
      // resetForm updates 6 fields, plus the 2 updates above = 8 state changes total
      // We verify the final state is valid
      verify: (bloc) {
        expect(bloc.state.isValid(), true);
        expect(bloc.categoryFieldBloc.value, VisitCategory.outpatient);
        expect(bloc.detailsFieldBloc.value, '');
      },
    );
  });
}

// Mock database implementation for testing
class _MockAppDatabase extends Mock implements AppDatabase {
  @override
  Future<List<Hospital>> getAllHospitals() async => [];

  @override
  Future<List<Department>> getAllDepartments() async => [];

  @override
  Future<List<Doctor>> getAllDoctors() async => [];

  @override
  Future<List<Resource>> getResourcesByVisit(int visitId) async => [];

  @override
  Future<int> createDepartment(DepartmentsCompanion companion) async => 1;

  @override
  Future<int> createDoctor(DoctorsCompanion companion) async => 1;

  @override
  Future<bool> updateHospital(Hospital hospital) async => true;

  @override
  Future<bool> updateVisit(Visit visit) async => true;
}

class _MockVisitFormBloc extends VisitFormBloc {
  _MockVisitFormBloc(super.database);
}
