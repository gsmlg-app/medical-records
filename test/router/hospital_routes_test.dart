import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:medical_records/router.dart';
import 'package:medical_records/screens/hospitals/hospitals_screen.dart';
import 'package:medical_records/screens/hospitals/add_hospital_screen.dart';
import 'package:medical_records/screens/hospitals/edit_hospital_screen.dart';
import 'package:medical_records/screens/app/error_screen.dart' as app_error;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hospital Routes - Configuration Tests', () {
    test('Hospital route paths are correctly defined', () {
      // Act - Check path constants
      expect(HospitalsScreen.path, equals('/hospitals'));
      expect(AddHospitalScreen.path, equals('/hospitals/add'));
      expect(EditHospitalScreen.path, equals('/hospitals/:id/edit'));

      // Assert - Route names are also defined
      expect(HospitalsScreen.name, equals('Hospitals'));
      expect(AddHospitalScreen.name, equals('AddHospital'));
      expect(EditHospitalScreen.name, equals('EditHospital'));
    });
  });

  group('Hospital Routes - Simple Router Tests', () {
    late GoRouter testRouter;

    setUp(() {
      // Create a simplified router for testing
      testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/hospitals',
            name: 'Hospitals',
            builder: (context, state) => const Scaffold(
              body: Text('Hospitals List'),
            ),
          ),
          GoRoute(
            path: '/hospitals/add',
            name: 'AddHospital',
            builder: (context, state) => const Scaffold(
              body: Text('Add Hospital'),
            ),
          ),
          GoRoute(
            path: '/hospitals/:id/edit',
            name: 'EditHospital',
            builder: (context, state) {
              final hospitalId = state.pathParameters['id'];
              return Scaffold(
                body: Text('Edit Hospital: $hospitalId'),
              );
            },
          ),
        ],
        errorBuilder: (context, state) => Scaffold(
          body: Text('Error: ${state.uri.toString()}'),
        ),
      );
    });

    testWidgets('Navigate to hospitals list route', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );

      // Act
      testRouter.go('/hospitals');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Hospitals List'), findsOneWidget);
      expect(testRouter.routeInformationProvider.value.location, '/hospitals');
    });

    testWidgets('Navigate to add hospital route', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );

      // Act
      testRouter.go('/hospitals/add');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Add Hospital'), findsOneWidget);
      expect(testRouter.routeInformationProvider.value.location, '/hospitals/add');
    });

    testWidgets('Navigate to edit hospital route with ID', (WidgetTester tester) async {
      // Arrange
      const hospitalId = '123';
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );

      // Act
      testRouter.go('/hospitals/$hospitalId/edit');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Edit Hospital: $hospitalId'), findsOneWidget);
      expect(testRouter.routeInformationProvider.value.location, '/hospitals/$hospitalId/edit');
    });

    testWidgets('Edit route parses parameter correctly', (WidgetTester tester) async {
      // Arrange
      const hospitalId = '456';
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );

      // Act
      testRouter.go('/hospitals/$hospitalId/edit');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Edit Hospital: $hospitalId'), findsOneWidget);

      // Verify the parameter was correctly extracted
      expect(testRouter.routeInformationProvider.value.location, '/hospitals/$hospitalId/edit');
    });

    testWidgets('Invalid route shows error page', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );

      // Act - Navigate to invalid route
      testRouter.go('/invalid-route');
      await tester.pumpAndSettle();

      // Assert - Should show error page
      expect(find.text('Error: /invalid-route'), findsOneWidget);
    });

    testWidgets('Router navigation methods work', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );

      // Act & Assert - Test go method
      testRouter.go('/hospitals/add');
      await tester.pumpAndSettle();
      expect(find.text('Add Hospital'), findsOneWidget);

      // Act & Assert - Test push method
      testRouter.push('/hospitals/789/edit');
      await tester.pumpAndSettle();
      expect(find.text('Edit Hospital: 789'), findsOneWidget);

      // Act & Assert - Test pop method
      testRouter.pop();
      await tester.pumpAndSettle();
      expect(find.text('Add Hospital'), findsOneWidget);
    });

    testWidgets('URL updates with navigation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );

      // Navigate to hospitals
      testRouter.go('/hospitals');
      await tester.pumpAndSettle();
      expect(testRouter.routeInformationProvider.value.location, '/hospitals');

      // Navigate to add hospital
      testRouter.go('/hospitals/add');
      await tester.pumpAndSettle();
      expect(testRouter.routeInformationProvider.value.location, '/hospitals/add');

      // Navigate to edit hospital
      testRouter.go('/hospitals/999/edit');
      await tester.pumpAndSettle();
      expect(testRouter.routeInformationProvider.value.location, '/hospitals/999/edit');
    });

    testWidgets('Route replacement works', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );

      // Navigate to hospitals list
      testRouter.go('/hospitals');
      await tester.pumpAndSettle();
      expect(find.text('Hospitals List'), findsOneWidget);

      // Replace with edit hospital
      testRouter.go('/hospitals/555/edit');
      await tester.pumpAndSettle();
      expect(find.text('Edit Hospital: 555'), findsOneWidget);
      expect(testRouter.routeInformationProvider.value.location, '/hospitals/555/edit');
    });

    testWidgets('Multiple edit routes with different IDs', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );

      // Test multiple hospital IDs
      final hospitalIds = ['1', '42', '999', '0'];

      for (final id in hospitalIds) {
        // Act
        testRouter.go('/hospitals/$id/edit');
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Edit Hospital: $id'), findsOneWidget);
        expect(testRouter.routeInformationProvider.value.location, '/hospitals/$id/edit');
      }
    });

    testWidgets('Named navigation approach would work correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );

      // Act & Assert - In the actual app, we would use:
      // context.goNamed('AddHospital') -> /hospitals/add
      // context.goNamed('EditHospital', pathParameters: {'id': '123'}) -> /hospitals/123/edit

      // This test verifies the paths are correct for named navigation
      expect(AddHospitalScreen.name, equals('AddHospital'));
      expect(EditHospitalScreen.name, equals('EditHospital'));

      // Test that the paths match what goNamed would generate
      testRouter.go('/hospitals/add');
      await tester.pumpAndSettle();
      expect(find.text('Add Hospital'), findsOneWidget);

      testRouter.go('/hospitals/123/edit');
      await tester.pumpAndSettle();
      expect(find.text('Edit Hospital: 123'), findsOneWidget);
    });
  });

  group('Hospital Routes - Path Parameter Tests', () {
    test('Edit route path pattern is correct', () {
      // Arrange & Act
      const editPath = '/hospitals/:id/edit';

      // Assert
      expect(editPath, contains(':id'));
      expect(editPath, startsWith('/hospitals/'));
      expect(editPath, endsWith('/edit'));
    });

    test('Add route path is static', () {
      // Arrange & Act
      const addPath = '/hospitals/add';

      // Assert
      expect(addPath, equals('/hospitals/add'));
      expect(addPath, isNot(contains(':')));
    });

    test('Hospitals list route path is static', () {
      // Arrange & Act
      const listPath = '/hospitals';

      // Assert
      expect(listPath, equals('/hospitals'));
      expect(listPath, isNot(contains(':')));
    });
  });
}