import 'package:app_database/app_database.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_database/src/enums.dart';

import 'package:visit_bloc/visit_bloc.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  group('VisitBloc', () {
    late AppDatabase mockDatabase;
    late VisitBloc visitBloc;

    setUpAll(() {
      registerFallbackValue(Visit(
        id: 1,
        treatmentId: 1,
        category: 'outpatient',
        date: DateTime.now(),
        details: 'Fallback',
        hospitalId: 1,
        departmentId: 1,
        doctorId: 1,
        informations: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      registerFallbackValue(VisitsCompanion.insert(
        treatmentId: 1,
        category: 'outpatient',
        date: DateTime.now(),
        details: '',
      ));
    });

    setUp(() {
      mockDatabase = MockAppDatabase();
      visitBloc = VisitBloc(mockDatabase);
    });

    tearDown(() {
      visitBloc.close();
    });

    test('initial state is VisitInitial', () {
      expect(visitBloc.state, equals(VisitInitial()));
    });

    group('LoadVisits', () {
      final mockVisits = [
        Visit(
          id: 1,
          treatmentId: 1,
          category: 'outpatient',
          date: DateTime(2023, 1, 1),
          details: 'Test Visit Details',
          hospitalId: 1,
          departmentId: 1,
          doctorId: 1,
          informations: '{"additional": "info"}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      blocTest<VisitBloc, VisitState>(
        'emits loading and loaded states when LoadVisits succeeds',
        setUp: () {
          when(() => mockDatabase.getAllVisits())
              .thenAnswer((_) async => mockVisits);
        },
        build: () => visitBloc,
        act: (bloc) => bloc.add(LoadVisits()),
        expect: () => [
          VisitLoading(),
          VisitLoaded(mockVisits),
        ],
      );

      blocTest<VisitBloc, VisitState>(
        'emits error state when LoadVisits fails',
        setUp: () {
          when(() => mockDatabase.getAllVisits())
              .thenThrow(Exception('Database error'));
        },
        build: () => visitBloc,
        act: (bloc) => bloc.add(LoadVisits()),
        expect: () => [
          VisitLoading(),
          const VisitError('Failed to load visits: Exception: Database error'),
        ],
      );
    });

    group('LoadVisitsByTreatment', () {
      const treatmentId = 1;
      final mockVisits = [
        Visit(
          id: 1,
          treatmentId: treatmentId,
          category: 'outpatient',
          date: DateTime(2023, 1, 1),
          details: 'Test Visit Details',
          hospitalId: 1,
          departmentId: 1,
          doctorId: 1,
          informations: '{"additional": "info"}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      blocTest<VisitBloc, VisitState>(
        'emits loading and loaded states when LoadVisitsByTreatment succeeds',
        setUp: () {
          when(() => mockDatabase.getVisitsByTreatment(treatmentId))
              .thenAnswer((_) async => mockVisits);
        },
        build: () => visitBloc,
        act: (bloc) => bloc.add(const LoadVisitsByTreatment(treatmentId)),
        expect: () => [
          VisitLoading(),
          VisitLoaded(mockVisits),
        ],
      );

      blocTest<VisitBloc, VisitState>(
        'emits error state when LoadVisitsByTreatment fails',
        setUp: () {
          when(() => mockDatabase.getVisitsByTreatment(treatmentId))
              .thenThrow(Exception('Database error'));
        },
        build: () => visitBloc,
        act: (bloc) => bloc.add(const LoadVisitsByTreatment(treatmentId)),
        expect: () => [
          VisitLoading(),
          const VisitError('Failed to load visits for treatment: Exception: Database error'),
        ],
      );
    });

    group('AddVisit', () {
      const treatmentId = 1;
      final category = VisitCategory.outpatient;
      final date = DateTime(2023, 1, 1);
      const details = 'New Visit Details';

      blocTest<VisitBloc, VisitState>(
        'emits loading, success, and loaded states when AddVisit succeeds',
        setUp: () {
          when(() => mockDatabase.createVisit(any()))
              .thenAnswer((_) async => 1);
          when(() => mockDatabase.getAllVisits())
              .thenAnswer((_) async => []);
        },
        build: () => visitBloc,
        act: (bloc) => bloc.add(AddVisit(
          treatmentId: treatmentId,
          category: category,
          date: date,
          details: details,
        )),
        expect: () => [
          VisitLoading(),
          const VisitOperationSuccess('Visit added successfully'),
          VisitLoaded([]),
        ],
      );

      blocTest<VisitBloc, VisitState>(
        'emits error state when AddVisit fails',
        setUp: () {
          when(() => mockDatabase.createVisit(any()))
              .thenThrow(Exception('Database error'));
        },
        build: () => visitBloc,
        act: (bloc) => bloc.add(AddVisit(
          treatmentId: treatmentId,
          category: category,
          date: date,
          details: details,
        )),
        expect: () => [
          VisitLoading(),
          const VisitError('Failed to add visit: Exception: Database error'),
        ],
      );
    });

    group('UpdateVisit', () {
      const visitId = 1;
      const treatmentId = 1;
      final category = VisitCategory.outpatient;
      final date = DateTime(2023, 1, 1);
      const details = 'Updated Visit Details';

      final existingVisit = Visit(
        id: visitId,
        treatmentId: treatmentId,
        category: 'outpatient',
        date: DateTime(2022, 1, 1),
        details: 'Old Visit Details',
        hospitalId: 1,
        departmentId: 1,
        doctorId: 1,
        informations: '{"additional": "info"}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      blocTest<VisitBloc, VisitState>(
        'emits loading, success, and loaded states when UpdateVisit succeeds',
        setUp: () {
          when(() => mockDatabase.getVisitById(visitId))
              .thenAnswer((_) async => existingVisit);
          when(() => mockDatabase.updateVisit(any()))
              .thenAnswer((_) async => true);
          when(() => mockDatabase.getAllVisits())
              .thenAnswer((_) async => []);
        },
        build: () => visitBloc,
        act: (bloc) => bloc.add(UpdateVisit(
          id: visitId,
          treatmentId: treatmentId,
          category: category,
          date: date,
          details: details,
        )),
        expect: () => [
          VisitLoading(),
          const VisitOperationSuccess('Visit updated successfully'),
          VisitLoaded([]),
        ],
      );

      blocTest<VisitBloc, VisitState>(
        'emits error state when UpdateVisit fails because visit not found',
        setUp: () {
          when(() => mockDatabase.getVisitById(visitId))
              .thenAnswer((_) async => null);
        },
        build: () => visitBloc,
        act: (bloc) => bloc.add(UpdateVisit(
          id: visitId,
          treatmentId: treatmentId,
          category: category,
          date: date,
          details: details,
        )),
        expect: () => [
          VisitLoading(),
          const VisitError('Visit not found'),
        ],
      );
    });

    group('DeleteVisit', () {
      const visitId = 1;

      blocTest<VisitBloc, VisitState>(
        'emits loading, success, and loaded states when DeleteVisit succeeds',
        setUp: () {
          when(() => mockDatabase.deleteVisit(visitId))
              .thenAnswer((_) async => 1);
          when(() => mockDatabase.getAllVisits())
              .thenAnswer((_) async => []);
        },
        build: () => visitBloc,
        act: (bloc) => bloc.add(const DeleteVisit(visitId)),
        expect: () => [
          VisitLoading(),
          const VisitOperationSuccess('Visit deleted successfully'),
          VisitLoaded([]),
        ],
      );

      blocTest<VisitBloc, VisitState>(
        'emits error state when DeleteVisit fails',
        setUp: () {
          when(() => mockDatabase.deleteVisit(visitId))
              .thenThrow(Exception('Database error'));
        },
        build: () => visitBloc,
        act: (bloc) => bloc.add(const DeleteVisit(visitId)),
        expect: () => [
          VisitLoading(),
          const VisitError('Failed to delete visit: Exception: Database error'),
        ],
      );
    });
  });
}