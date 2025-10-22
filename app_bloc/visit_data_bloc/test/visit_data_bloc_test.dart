import 'package:app_database/app_database.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visit_data_bloc/visit_data_bloc.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

// MockVisitBloc removed as VisitBloc might not be available

class MockVisit extends Mock implements Visit {}

void main() {
  group('VisitDataBloc', () {
    late MockAppDatabase mockDatabase;
    late VisitDataBloc dataBloc;

    setUp(() {
      mockDatabase = MockAppDatabase();
      dataBloc = VisitDataBloc(mockDatabase);
    });

    tearDown(() {
      dataBloc.close();
    });

    test('initial state is VisitDataStateInitial', () {
      expect(dataBloc.state, const VisitDataStateInitial());
    });

    group('CreateVisit', () {
      final mockVisit = MockVisit();
      when(() => mockVisit.id).thenReturn(1);
      when(() => mockVisit.treatmentId).thenReturn(1);
      when(() => mockVisit.category).thenReturn('outpatient');
      when(() => mockVisit.date).thenReturn(DateTime.now());
      when(() => mockVisit.details).thenReturn('Test details');
      when(() => mockVisit.hospitalId).thenReturn(1);
      when(() => mockVisit.departmentId).thenReturn(1);
      when(() => mockVisit.doctorId).thenReturn(1);
      when(() => mockVisit.createdAt).thenReturn(DateTime.now());

      blocTest<VisitDataBloc, VisitDataState>(
        'emits success state when visit is created successfully',
        setUp: () {
          when(
            () => mockDatabase.createVisit(any()),
          ).thenAnswer((_) async => 1);
        },
        build: () => dataBloc,
        act: (bloc) => bloc.add(
          CreateVisit(
            treatmentId: 1,
            category: VisitCategory.outpatient,
            date: DateTime.now(),
            details: 'Test details',
            hospitalId: 1,
            departmentId: 1,
            doctorId: 1,
          ),
        ),
        expect: () => [
          const VisitDataStateLoading(),
          isA<VisitDataStateSuccess>(),
        ],
      );

      blocTest<VisitDataBloc, VisitDataState>(
        'emits error state when creation fails',
        setUp: () {
          when(
            () => mockDatabase.createVisit(any()),
          ).thenThrow(Exception('Database error'));
        },
        build: () => dataBloc,
        act: (bloc) => bloc.add(
          CreateVisit(
            treatmentId: 1,
            category: VisitCategory.outpatient,
            date: DateTime.now(),
            details: 'Test details',
          ),
        ),
        expect: () => [
          const VisitDataStateLoading(),
          isA<VisitDataStateError>(),
        ],
      );
    });

    group('UpdateVisitData', () {
      final mockVisit = MockVisit();
      when(() => mockVisit.id).thenReturn(1);
      when(() => mockVisit.treatmentId).thenReturn(1);
      when(() => mockVisit.category).thenReturn('outpatient');
      when(() => mockVisit.date).thenReturn(DateTime.now());
      when(() => mockVisit.details).thenReturn('Test details');
      when(() => mockVisit.hospitalId).thenReturn(1);
      when(() => mockVisit.departmentId).thenReturn(1);
      when(() => mockVisit.doctorId).thenReturn(1);
      when(() => mockVisit.createdAt).thenReturn(DateTime.now());

      blocTest<VisitDataBloc, VisitDataState>(
        'emits success state when visit is updated successfully',
        setUp: () {
          when(
            () => mockDatabase.getVisit(1),
          ).thenAnswer((_) async => mockVisit);
          when(
            () => mockDatabase.updateVisitData(1, any()),
          ).thenAnswer((_) async => 1);
        },
        build: () => dataBloc,
        act: (bloc) => bloc.add(
          UpdateVisitData(
            visitId: 1,
            treatmentId: 1,
            category: VisitCategory.outpatient,
            date: DateTime.now(),
            details: 'Updated details',
            hospitalId: 1,
            departmentId: 1,
            doctorId: 1,
          ),
        ),
        expect: () => [
          const VisitDataStateLoading(),
          isA<VisitDataStateSuccess>(),
        ],
      );

      blocTest<VisitDataBloc, VisitDataState>(
        'emits error state when visit is not found',
        setUp: () {
          when(() => mockDatabase.getVisit(1)).thenAnswer((_) async => null);
        },
        build: () => dataBloc,
        act: (bloc) => bloc.add(
          UpdateVisitData(
            visitId: 1,
            treatmentId: 1,
            category: VisitCategory.outpatient,
            date: DateTime.now(),
            details: 'Updated details',
          ),
        ),
        expect: () => [
          const VisitDataStateLoading(),
          const VisitDataStateError('Visit not found'),
        ],
      );
    });

    group('DeleteVisit', () {
      final mockVisit = MockVisit();
      when(() => mockVisit.id).thenReturn(1);
      when(() => mockVisit.treatmentId).thenReturn(1);
      when(() => mockVisit.category).thenReturn('outpatient');
      when(() => mockVisit.date).thenReturn(DateTime.now());
      when(() => mockVisit.details).thenReturn('Test details');
      when(() => mockVisit.hospitalId).thenReturn(1);
      when(() => mockVisit.departmentId).thenReturn(1);
      when(() => mockVisit.doctorId).thenReturn(1);
      when(() => mockVisit.createdAt).thenReturn(DateTime.now());

      blocTest<VisitDataBloc, VisitDataState>(
        'emits success state when visit is deleted successfully',
        setUp: () {
          when(
            () => mockDatabase.getVisit(1),
          ).thenAnswer((_) async => mockVisit);
          when(
            () => mockDatabase.deleteResourcesByVisitId(1),
          ).thenAnswer((_) async => 1);
          when(() => mockDatabase.deleteVisit(1)).thenAnswer((_) async => 1);
        },
        build: () => dataBloc,
        act: (bloc) => bloc.add(const DeleteVisit(1)),
        expect: () => [
          const VisitDataStateLoading(),
          isA<VisitDataStateSuccess>(),
        ],
      );

      blocTest<VisitDataBloc, VisitDataState>(
        'emits error state when visit is not found',
        setUp: () {
          when(() => mockDatabase.getVisit(1)).thenAnswer((_) async => null);
        },
        build: () => dataBloc,
        act: (bloc) => bloc.add(const DeleteVisit(1)),
        expect: () => [
          const VisitDataStateLoading(),
          const VisitDataStateError('Visit not found'),
        ],
      );
    });

    group('LoadVisit', () {
      final mockVisit = MockVisit();
      when(() => mockVisit.id).thenReturn(1);
      when(() => mockVisit.treatmentId).thenReturn(1);
      when(() => mockVisit.category).thenReturn('outpatient');
      when(() => mockVisit.date).thenReturn(DateTime.now());
      when(() => mockVisit.details).thenReturn('Test details');
      when(() => mockVisit.hospitalId).thenReturn(1);
      when(() => mockVisit.departmentId).thenReturn(1);
      when(() => mockVisit.doctorId).thenReturn(1);
      when(() => mockVisit.createdAt).thenReturn(DateTime.now());

      blocTest<VisitDataBloc, VisitDataState>(
        'emits success state when visit is loaded successfully',
        setUp: () {
          when(
            () => mockDatabase.getVisit(1),
          ).thenAnswer((_) async => mockVisit);
        },
        build: () => dataBloc,
        act: (bloc) => bloc.add(const LoadVisit(1)),
        expect: () => [
          const VisitDataStateLoading(),
          isA<VisitDataStateSuccess>(),
        ],
      );

      blocTest<VisitDataBloc, VisitDataState>(
        'emits error state when visit is not found',
        setUp: () {
          when(() => mockDatabase.getVisit(1)).thenAnswer((_) async => null);
        },
        build: () => dataBloc,
        act: (bloc) => bloc.add(const LoadVisit(1)),
        expect: () => [
          const VisitDataStateLoading(),
          const VisitDataStateError('Visit not found'),
        ],
      );
    });
  });
}
