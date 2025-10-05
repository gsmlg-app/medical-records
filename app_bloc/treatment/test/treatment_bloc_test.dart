import 'package:app_database/app_database.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:treatment_bloc/treatment_bloc.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  group('TreatmentBloc', () {
    late AppDatabase mockDatabase;
    late TreatmentBloc treatmentBloc;

    setUpAll(() {
      registerFallbackValue(Treatment(
        id: 1,
        title: 'Fallback',
        diagnosis: 'Fallback',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      registerFallbackValue(TreatmentsCompanion.insert(
        title: '',
        diagnosis: '',
        startDate: DateTime.now(),
      ));
    });

    setUp(() {
      mockDatabase = MockAppDatabase();
      treatmentBloc = TreatmentBloc(mockDatabase);
    });

    tearDown(() {
      treatmentBloc.close();
    });

    test('initial state is TreatmentInitial', () {
      expect(treatmentBloc.state, equals(TreatmentInitial()));
    });

    group('LoadTreatments', () {
      final mockTreatments = [
        Treatment(
          id: 1,
          title: 'Test Treatment',
          diagnosis: 'Test Diagnosis',
          startDate: DateTime(2023, 1, 1),
          endDate: DateTime(2023, 12, 31),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      blocTest<TreatmentBloc, TreatmentState>(
        'emits loading and loaded states when LoadTreatments succeeds',
        setUp: () {
          when(() => mockDatabase.getAllTreatments())
              .thenAnswer((_) async => mockTreatments);
        },
        build: () => treatmentBloc,
        act: (bloc) => bloc.add(LoadTreatments()),
        expect: () => [
          TreatmentLoading(),
          TreatmentLoaded(mockTreatments),
        ],
      );

      blocTest<TreatmentBloc, TreatmentState>(
        'emits error state when LoadTreatments fails',
        setUp: () {
          when(() => mockDatabase.getAllTreatments())
              .thenThrow(Exception('Database error'));
        },
        build: () => treatmentBloc,
        act: (bloc) => bloc.add(LoadTreatments()),
        expect: () => [
          TreatmentLoading(),
          const TreatmentError('Failed to load treatments: Exception: Database error'),
        ],
      );
    });

    group('AddTreatment', () {
      const title = 'New Treatment';
      const diagnosis = 'New Diagnosis';
      final startDate = DateTime(2023, 1, 1);
      final endDate = DateTime(2023, 12, 31);

      blocTest<TreatmentBloc, TreatmentState>(
        'emits loading, success, and loaded states when AddTreatment succeeds',
        setUp: () {
          when(() => mockDatabase.createTreatment(any()))
              .thenAnswer((_) async => 1);
          when(() => mockDatabase.getAllTreatments())
              .thenAnswer((_) async => []);
        },
        build: () => treatmentBloc,
        act: (bloc) => bloc.add(AddTreatment(
          title: title,
          diagnosis: diagnosis,
          startDate: startDate,
          endDate: endDate,
        )),
        expect: () => [
          TreatmentLoading(),
          const TreatmentOperationSuccess('Treatment added successfully'),
          TreatmentLoaded([]),
        ],
      );

      blocTest<TreatmentBloc, TreatmentState>(
        'emits error state when AddTreatment fails',
        setUp: () {
          when(() => mockDatabase.createTreatment(any()))
              .thenThrow(Exception('Database error'));
        },
        build: () => treatmentBloc,
        act: (bloc) => bloc.add(AddTreatment(
          title: title,
          diagnosis: diagnosis,
          startDate: startDate,
          endDate: endDate,
        )),
        expect: () => [
          TreatmentLoading(),
          const TreatmentError('Failed to add treatment: Exception: Database error'),
        ],
      );
    });

    group('UpdateTreatment', () {
      const treatmentId = 1;
      const title = 'Updated Treatment';
      const diagnosis = 'Updated Diagnosis';
      final startDate = DateTime(2023, 1, 1);
      final endDate = DateTime(2023, 12, 31);

      final existingTreatment = Treatment(
        id: treatmentId,
        title: 'Old Treatment',
        diagnosis: 'Old Diagnosis',
        startDate: DateTime(2022, 1, 1),
        endDate: DateTime(2022, 12, 31),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      blocTest<TreatmentBloc, TreatmentState>(
        'emits loading, success, and loaded states when UpdateTreatment succeeds',
        setUp: () {
          when(() => mockDatabase.getTreatmentById(treatmentId))
              .thenAnswer((_) async => existingTreatment);
          when(() => mockDatabase.updateTreatment(any()))
              .thenAnswer((_) async => true);
          when(() => mockDatabase.getAllTreatments())
              .thenAnswer((_) async => []);
        },
        build: () => treatmentBloc,
        act: (bloc) => bloc.add(UpdateTreatment(
          id: treatmentId,
          title: title,
          diagnosis: diagnosis,
          startDate: startDate,
          endDate: endDate,
        )),
        expect: () => [
          TreatmentLoading(),
          const TreatmentOperationSuccess('Treatment updated successfully'),
          TreatmentLoaded([]),
        ],
      );

      blocTest<TreatmentBloc, TreatmentState>(
        'emits error state when UpdateTreatment fails because treatment not found',
        setUp: () {
          when(() => mockDatabase.getTreatmentById(treatmentId))
              .thenAnswer((_) async => null);
        },
        build: () => treatmentBloc,
        act: (bloc) => bloc.add(UpdateTreatment(
          id: treatmentId,
          title: title,
          diagnosis: diagnosis,
          startDate: startDate,
          endDate: endDate,
        )),
        expect: () => [
          TreatmentLoading(),
          const TreatmentError('Treatment not found'),
        ],
      );
    });

    group('DeleteTreatment', () {
      const treatmentId = 1;

      blocTest<TreatmentBloc, TreatmentState>(
        'emits loading, success, and loaded states when DeleteTreatment succeeds',
        setUp: () {
          when(() => mockDatabase.deleteTreatment(treatmentId))
              .thenAnswer((_) async => 1);
          when(() => mockDatabase.getAllTreatments())
              .thenAnswer((_) async => []);
        },
        build: () => treatmentBloc,
        act: (bloc) => bloc.add(const DeleteTreatment(treatmentId)),
        expect: () => [
          TreatmentLoading(),
          const TreatmentOperationSuccess('Treatment deleted successfully'),
          TreatmentLoaded([]),
        ],
      );

      blocTest<TreatmentBloc, TreatmentState>(
        'emits error state when DeleteTreatment fails',
        setUp: () {
          when(() => mockDatabase.deleteTreatment(treatmentId))
              .thenThrow(Exception('Database error'));
        },
        build: () => treatmentBloc,
        act: (bloc) => bloc.add(const DeleteTreatment(treatmentId)),
        expect: () => [
          TreatmentLoading(),
          const TreatmentError('Failed to delete treatment: Exception: Database error'),
        ],
      );
    });
  });
}