import 'package:app_database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_lib/locale/gen_l10n/app_localizations.dart';
import 'package:medical_records/screens/treatments/treatments_screen.dart';
import 'package:treatment_bloc/treatment_bloc.dart';

class MockTreatmentBloc extends MockBloc<TreatmentEvent, TreatmentState>
    implements TreatmentBloc {}

Widget createTestWidget({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en', ''),
    ],
    home: child,
  );
}

void main() {
  group('TreatmentsScreen', () {
    late MockTreatmentBloc mockTreatmentBloc;

    setUp(() {
      mockTreatmentBloc = MockTreatmentBloc();
    });

    testWidgets('renders empty state when no treatments', (tester) async {
      when(() => mockTreatmentBloc.state).thenReturn(TreatmentInitial());

      await tester.pumpWidget(
        createTestWidget(
          child: BlocProvider<TreatmentBloc>.value(
            value: mockTreatmentBloc,
            child: const TreatmentsScreen(),
          ),
        ),
      );

      expect(find.text('No treatments added yet'), findsOneWidget);
      expect(find.text('Add Treatment'), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      when(() => mockTreatmentBloc.state).thenReturn(TreatmentLoading());

      await tester.pumpWidget(
        createTestWidget(
          child: BlocProvider<TreatmentBloc>.value(
            value: mockTreatmentBloc,
            child: const TreatmentsScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders treatments list when treatments are loaded', (tester) async {
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

      when(() => mockTreatmentBloc.state).thenReturn(TreatmentLoaded(mockTreatments));

      await tester.pumpWidget(
        createTestWidget(
          child: BlocProvider<TreatmentBloc>.value(
            value: mockTreatmentBloc,
            child: const TreatmentsScreen(),
          ),
        ),
      );

      expect(find.text('Test Treatment'), findsOneWidget);
      expect(find.text('Test Diagnosis'), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      when(() => mockTreatmentBloc.state).thenReturn(
        const TreatmentError('Failed to load treatments'),
      );

      await tester.pumpWidget(
        createTestWidget(
          child: BlocProvider<TreatmentBloc>.value(
            value: mockTreatmentBloc,
            child: const TreatmentsScreen(),
          ),
        ),
      );

      expect(find.text('Failed to load treatments'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}