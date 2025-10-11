import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:visit_form_bloc/visit_form_bloc.dart';
import 'package:app_database/src/enums.dart';

void main() {
  group('VisitFormBloc', () {
    late VisitFormBloc visitFormBloc;

    setUp(() {
      visitFormBloc = VisitFormBloc();
    });

    tearDown(() {
      visitFormBloc.close();
    });

    test('initial state is correct', () {
      expect(visitFormBloc.state, equals(VisitFormState.initial()));
    });

    blocTest<VisitFormBloc, VisitFormState>(
      'emits updated state when category is changed',
      build: () => visitFormBloc,
      act: (bloc) =>
          bloc.add(const VisitFormCategoryChanged(VisitCategory.inpatient)),
      expect: () => [
        isA<VisitFormState>()
          ..having(
            (s) => s.category,
            'category',
            equals(VisitCategory.inpatient),
          )
          ..having(
            (s) => s.status,
            'status',
            equals(VisitFormStatus.invalid),
          ), // Not valid yet
      ],
    );

    blocTest<VisitFormBloc, VisitFormState>(
      'emits updated state when date is changed',
      build: () => visitFormBloc,
      act: (bloc) => bloc.add(VisitFormDateChanged(DateTime(2023, 1, 1))),
      expect: () => [
        isA<VisitFormState>()
          ..having((s) => s.date, 'date', equals(DateTime(2023, 1, 1)))
          ..having(
            (s) => s.status,
            'status',
            equals(VisitFormStatus.invalid),
          ), // Not valid yet
      ],
    );

    blocTest<VisitFormBloc, VisitFormState>(
      'emits updated state when details is changed',
      build: () => visitFormBloc,
      act: (bloc) => bloc.add(const VisitFormDetailsChanged('Test Details')),
      expect: () => [
        isA<VisitFormState>()
          ..having((s) => s.details, 'details', equals('Test Details'))
          ..having(
            (s) => s.status,
            'status',
            equals(VisitFormStatus.invalid),
          ), // Not valid yet
      ],
    );

    blocTest<VisitFormBloc, VisitFormState>(
      'emits valid form state when all required fields are filled',
      build: () => visitFormBloc,
      act: (bloc) async {
        bloc.add(const VisitFormCategoryChanged(VisitCategory.outpatient));
        bloc.add(VisitFormDateChanged(DateTime(2023, 1, 1)));
        bloc.add(const VisitFormDetailsChanged('Test Details'));
      },
      expect: () => [
        isA<VisitFormState>()
          ..having(
            (s) => s.category,
            'category',
            equals(VisitCategory.outpatient),
          )
          ..having((s) => s.status, 'status', equals(VisitFormStatus.invalid)),
        isA<VisitFormState>()
          ..having((s) => s.date, 'date', equals(DateTime(2023, 1, 1)))
          ..having((s) => s.status, 'status', equals(VisitFormStatus.invalid)),
        isA<VisitFormState>()
          ..having((s) => s.details, 'details', equals('Test Details'))
          ..having(
            (s) => s.status,
            'status',
            equals(VisitFormStatus.valid),
          ), // Now form is valid
      ],
    );

    blocTest<VisitFormBloc, VisitFormState>(
      'emits updated state when hospitalId is changed',
      build: () => visitFormBloc,
      act: (bloc) => bloc.add(const VisitFormHospitalIdChanged(1)),
      expect: () => [
        isA<VisitFormState>()
          ..having((s) => s.hospitalId, 'hospitalId', equals(1)),
      ],
    );

    blocTest<VisitFormBloc, VisitFormState>(
      'emits updated state when departmentId is changed',
      build: () => visitFormBloc,
      act: (bloc) => bloc.add(const VisitFormDepartmentIdChanged(1)),
      expect: () => [
        isA<VisitFormState>()
          ..having((s) => s.departmentId, 'departmentId', equals(1)),
      ],
    );

    blocTest<VisitFormBloc, VisitFormState>(
      'emits updated state when doctorId is changed',
      build: () => visitFormBloc,
      act: (bloc) => bloc.add(const VisitFormDoctorIdChanged(1)),
      expect: () => [
        isA<VisitFormState>()..having((s) => s.doctorId, 'doctorId', equals(1)),
      ],
    );

    blocTest<VisitFormBloc, VisitFormState>(
      'emits updated state when informations is changed',
      build: () => visitFormBloc,
      act: (bloc) => bloc.add(const VisitFormInformationsChanged('Test Info')),
      expect: () => [
        isA<VisitFormState>()
          ..having((s) => s.informations, 'informations', equals('Test Info')),
      ],
    );

    blocTest<VisitFormBloc, VisitFormState>(
      'emits initial state when reset is added',
      build: () => visitFormBloc,
      act: (bloc) async {
        // First add some data
        bloc.add(const VisitFormCategoryChanged(VisitCategory.inpatient));
        bloc.add(const VisitFormDetailsChanged('Test Details'));
        // Then reset
        bloc.add(const VisitFormReset());
      },
      expect: () => [
        isA<VisitFormState>()..having(
          (s) => s.category,
          'category',
          equals(VisitCategory.inpatient),
        ),
        isA<VisitFormState>()
          ..having((s) => s.details, 'details', equals('Test Details')),
        isA<VisitFormState>()
          ..having(
            (s) => s.category,
            'category',
            equals(VisitCategory.outpatient),
          )
          ..having((s) => s.date, 'date', isNull)
          ..having((s) => s.details, 'details', equals(''))
          ..having((s) => s.hospitalId, 'hospitalId', isNull)
          ..having((s) => s.departmentId, 'departmentId', isNull)
          ..having((s) => s.doctorId, 'doctorId', isNull)
          ..having((s) => s.informations, 'informations', isNull)
          ..having((s) => s.status, 'status', equals(VisitFormStatus.initial)),
      ],
    );

    blocTest<VisitFormBloc, VisitFormState>(
      'emits populated state when VisitFormPopulate is added',
      build: () => visitFormBloc,
      act: (bloc) => bloc.add(
        VisitFormPopulate({
          'category': VisitCategory.inpatient,
          'date': DateTime(2023, 1, 1),
          'details': 'Test Details',
          'hospitalId': 1,
          'departmentId': 2,
          'doctorId': 3,
          'informations': 'Test Info',
        }),
      ),
      expect: () => [
        isA<VisitFormState>()
          ..having(
            (s) => s.category,
            'category',
            equals(VisitCategory.inpatient),
          )
          ..having((s) => s.date, 'date', equals(DateTime(2023, 1, 1)))
          ..having((s) => s.details, 'details', equals('Test Details'))
          ..having((s) => s.hospitalId, 'hospitalId', equals(1))
          ..having((s) => s.departmentId, 'departmentId', equals(2))
          ..having((s) => s.doctorId, 'doctorId', equals(3))
          ..having((s) => s.informations, 'informations', equals('Test Info'))
          ..having((s) => s.status, 'status', equals(VisitFormStatus.valid)),
      ],
    );
  });
}
