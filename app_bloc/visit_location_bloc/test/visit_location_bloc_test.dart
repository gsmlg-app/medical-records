import 'package:app_database/app_database.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visit_location_bloc/visit_location_bloc.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class MockHospital extends Mock implements Hospital {}

class MockDepartment extends Mock implements Department {}

class MockDoctor extends Mock implements Doctor {}

void main() {
  group('VisitLocationBloc', () {
    late MockAppDatabase mockDatabase;
    late VisitLocationBloc locationBloc;

    setUp(() {
      mockDatabase = MockAppDatabase();
      locationBloc = VisitLocationBloc(mockDatabase);
    });

    tearDown(() {
      locationBloc.close();
    });

    test('initial state is VisitLocationStateInitial', () {
      expect(locationBloc.state, const VisitLocationStateInitial());
    });

    group('LoadHospitals', () {
      blocTest<VisitLocationBloc, VisitLocationState>(
        'emits loaded state when data loads successfully',
        setUp: () {
          when(
            () => mockDatabase.getAllHospitals(),
          ).thenAnswer((_) async => []);
          when(
            () => mockDatabase.getAllDepartments(),
          ).thenAnswer((_) async => []);
          when(() => mockDatabase.getAllDoctors()).thenAnswer((_) async => []);
        },
        build: () => locationBloc,
        act: (bloc) => bloc.add(const LoadHospitals()),
        expect: () => [
          const VisitLocationStateLoading(),
          const VisitLocationStateLoaded(
            hospitals: [],
            departments: [],
            doctors: [],
          ),
        ],
      );

      blocTest<VisitLocationBloc, VisitLocationState>(
        'emits error state when loading fails',
        setUp: () {
          when(
            () => mockDatabase.getAllHospitals(),
          ).thenThrow(Exception('Database error'));
        },
        build: () => locationBloc,
        act: (bloc) => bloc.add(const LoadHospitals()),
        expect: () => [
          const VisitLocationStateLoading(),
          const VisitLocationStateError('Exception: Database error'),
        ],
      );
    });

    group('RefreshHospitals', () {
      final mockHospital = MockHospital();
      when(() => mockHospital.id).thenReturn(1);
      when(() => mockHospital.name).thenReturn('Test Hospital');
      when(() => mockHospital.createdAt).thenReturn(DateTime.now());

      blocTest<VisitLocationBloc, VisitLocationState>(
        'emits loaded state with newest hospital when selectNewest is true',
        setUp: () {
          when(
            () => mockDatabase.getAllHospitals(),
          ).thenAnswer((_) async => [mockHospital]);
          when(
            () => mockDatabase.getAllDepartments(),
          ).thenAnswer((_) async => []);
          when(() => mockDatabase.getAllDoctors()).thenAnswer((_) async => []);
        },
        build: () => locationBloc,
        act: (bloc) => bloc.add(const RefreshHospitals(selectNewest: true)),
        expect: () => [
          const VisitLocationStateLoading(),
          VisitLocationStateLoaded(
            hospitals: [mockHospital],
            departments: [],
            doctors: [],
            selectedHospitalId: 1,
            newestHospital: mockHospital,
          ),
        ],
      );
    });

    group('HospitalChanged', () {
      final mockHospital = MockHospital();
      final mockDepartment = MockDepartment();
      final mockDoctor = MockDoctor();

      setUp(() {
        when(
          () => mockDatabase.getAllHospitals(),
        ).thenAnswer((_) async => [mockHospital]);
        when(
          () => mockDatabase.getAllDepartments(),
        ).thenAnswer((_) async => [mockDepartment]);
        when(
          () => mockDatabase.getAllDoctors(),
        ).thenAnswer((_) async => [mockDoctor]);
        when(
          () => mockDatabase.getHospital(any()),
        ).thenAnswer((_) async => mockHospital);
        when(
          () => mockDatabase.getDepartmentById(any()),
        ).thenAnswer((_) async => mockDepartment);
      });

      blocTest<VisitLocationBloc, VisitLocationState>(
        'clears department and doctor selection when hospital changes',
        build: () => locationBloc,
        seed: () => VisitLocationStateLoaded(
          hospitals: [mockHospital],
          departments: [mockDepartment],
          doctors: [mockDoctor],
          selectedHospitalId: 1,
          selectedDepartmentId: 2,
          selectedDoctorId: 3,
        ),
        act: (bloc) => bloc.add(const HospitalChanged(4)),
        expect: () => [
          VisitLocationStateLoaded(
            hospitals: [mockHospital],
            departments: [mockDepartment],
            doctors: [mockDoctor],
            selectedHospitalId: 4,
            selectedDepartmentId: null,
            selectedDoctorId: null,
          ),
        ],
      );
    });

    group('DepartmentChanged', () {
      final mockHospital = MockHospital();
      final mockDepartment = MockDepartment();
      final mockDoctor = MockDoctor();

      setUp(() {
        when(
          () => mockDatabase.getAllHospitals(),
        ).thenAnswer((_) async => [mockHospital]);
        when(
          () => mockDatabase.getAllDepartments(),
        ).thenAnswer((_) async => [mockDepartment]);
        when(
          () => mockDatabase.getAllDoctors(),
        ).thenAnswer((_) async => [mockDoctor]);
      });

      blocTest<VisitLocationBloc, VisitLocationState>(
        'clears doctor selection when department changes',
        build: () => locationBloc,
        seed: () => VisitLocationStateLoaded(
          hospitals: [mockHospital],
          departments: [mockDepartment],
          doctors: [mockDoctor],
          selectedHospitalId: 1,
          selectedDepartmentId: 2,
          selectedDoctorId: 3,
        ),
        act: (bloc) => bloc.add(const DepartmentChanged(4)),
        expect: () => [
          VisitLocationStateLoaded(
            hospitals: [mockHospital],
            departments: [mockDepartment],
            doctors: [mockDoctor],
            selectedHospitalId: 1,
            selectedDepartmentId: 4,
            selectedDoctorId: null,
          ),
        ],
      );
    });
  });
}
