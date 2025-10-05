import 'package:app_database/app_database.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:treatment_form_bloc/treatment_form_bloc.dart';

void main() {
  group('TreatmentFormBloc', () {
    late TreatmentFormBloc treatmentFormBloc;

    setUp(() {
      treatmentFormBloc = TreatmentFormBloc();
    });

    tearDown(() {
      treatmentFormBloc.close();
    });

    test('initial state is correct', () {
      expect(treatmentFormBloc.state, equals(TreatmentFormState.initial()));
    });

    blocTest<TreatmentFormBloc, TreatmentFormState>(
      'emits updated state when title is changed',
      build: () => treatmentFormBloc,
      act: (bloc) => bloc.add(const TreatmentFormTitleChanged('Test Title')),
      expect: () => [
        isA<TreatmentFormState>()
          ..having((s) => s.title, 'title', equals('Test Title'))
          ..having((s) => s.isTitleValid, 'isTitleValid', isTrue)
          ..having((s) => s.isFormValid, 'isFormValid', isFalse), // Form not valid yet
      ],
    );

    blocTest<TreatmentFormBloc, TreatmentFormState>(
      'emits updated state when diagnosis is changed',
      build: () => treatmentFormBloc,
      act: (bloc) => bloc.add(const TreatmentFormDiagnosisChanged('Test Diagnosis')),
      expect: () => [
        isA<TreatmentFormState>()
          ..having((s) => s.diagnosis, 'diagnosis', equals('Test Diagnosis'))
          ..having((s) => s.isDiagnosisValid, 'isDiagnosisValid', isTrue)
          ..having((s) => s.isFormValid, 'isFormValid', isFalse), // Form not valid yet
      ],
    );

    blocTest<TreatmentFormBloc, TreatmentFormState>(
      'emits updated state when start date is changed',
      build: () => treatmentFormBloc,
      act: (bloc) => bloc.add(TreatmentFormStartDateChanged(DateTime(2023, 1, 1))),
      expect: () => [
        isA<TreatmentFormState>()
          ..having((s) => s.startDate, 'startDate', equals(DateTime(2023, 1, 1)))
          ..having((s) => s.isStartDateValid, 'isStartDateValid', isTrue)
          ..having((s) => s.isFormValid, 'isFormValid', isFalse), // Form not valid yet
      ],
    );

    blocTest<TreatmentFormBloc, TreatmentFormState>(
      'emits valid form state when all required fields are filled',
      build: () => treatmentFormBloc,
      act: (bloc) async {
        bloc.add(const TreatmentFormTitleChanged('Test Title'));
        bloc.add(const TreatmentFormDiagnosisChanged('Test Diagnosis'));
        bloc.add(TreatmentFormStartDateChanged(DateTime(2023, 1, 1)));
      },
      expect: () => [
        isA<TreatmentFormState>()
          ..having((s) => s.title, 'title', equals('Test Title'))
          ..having((s) => s.isTitleValid, 'isTitleValid', isTrue)
          ..having((s) => s.isFormValid, 'isFormValid', isFalse),
        isA<TreatmentFormState>()
          ..having((s) => s.diagnosis, 'diagnosis', equals('Test Diagnosis'))
          ..having((s) => s.isDiagnosisValid, 'isDiagnosisValid', isTrue)
          ..having((s) => s.isFormValid, 'isFormValid', isFalse),
        isA<TreatmentFormState>()
          ..having((s) => s.startDate, 'startDate', equals(DateTime(2023, 1, 1)))
          ..having((s) => s.isStartDateValid, 'isStartDateValid', isTrue)
          ..having((s) => s.isFormValid, 'isFormValid', isTrue), // Now form is valid
      ],
    );

    blocTest<TreatmentFormBloc, TreatmentFormState>(
      'emits updated state when end date is changed',
      build: () => treatmentFormBloc,
      act: (bloc) => bloc.add(TreatmentFormEndDateChanged(DateTime(2023, 2, 1))),
      expect: () => [
        isA<TreatmentFormState>()
          ..having((s) => s.endDate, 'endDate', equals(DateTime(2023, 2, 1))),
      ],
    );

    blocTest<TreatmentFormBloc, TreatmentFormState>(
      'emits initial state when reset is added',
      build: () => treatmentFormBloc,
      act: (bloc) async {
        // First add some data
        bloc.add(const TreatmentFormTitleChanged('Test Title'));
        bloc.add(const TreatmentFormDiagnosisChanged('Test Diagnosis'));
        // Then reset
        bloc.add(const TreatmentFormReset());
      },
      expect: () => [
        isA<TreatmentFormState>()
          ..having((s) => s.title, 'title', equals('Test Title')),
        isA<TreatmentFormState>()
          ..having((s) => s.diagnosis, 'diagnosis', equals('Test Diagnosis')),
        isA<TreatmentFormState>()
          ..having((s) => s.title, 'title', equals(''))
          ..having((s) => s.diagnosis, 'diagnosis', equals(''))
          ..having((s) => s.startDate, 'startDate', isNull)
          ..having((s) => s.endDate, 'endDate', isNull)
          ..having((s) => s.isFormValid, 'isFormValid', isFalse),
      ],
    );

    blocTest<TreatmentFormBloc, TreatmentFormState>(
      'emits populated state when TreatmentFormPopulate is added',
      build: () => treatmentFormBloc,
      act: (bloc) => bloc.add(TreatmentFormPopulate(
        Treatment(
          id: 1,
          title: 'Existing Treatment',
          diagnosis: 'Existing Diagnosis',
          startDate: DateTime(2023, 1, 1),
          endDate: DateTime(2023, 2, 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      )),
      expect: () => [
        isA<TreatmentFormState>()
          ..having((s) => s.title, 'title', equals('Existing Treatment'))
          ..having((s) => s.diagnosis, 'diagnosis', equals('Existing Diagnosis'))
          ..having((s) => s.startDate, 'startDate', equals(DateTime(2023, 1, 1)))
          ..having((s) => s.endDate, 'endDate', equals(DateTime(2023, 2, 1)))
          ..having((s) => s.isFormValid, 'isFormValid', isTrue),
      ],
    );
  });
}