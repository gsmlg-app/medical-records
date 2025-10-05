import 'package:flutter/material.dart';
import 'package:medical_records/screens/app/error_screen.dart';
import 'package:medical_records/screens/app/splash_screen.dart';
import 'package:medical_records/screens/home/home_screen.dart';
import 'package:medical_records/screens/hospitals/hospitals_screen.dart';
import 'package:medical_records/screens/hospitals/add_hospital_screen.dart';
import 'package:medical_records/screens/hospitals/edit_hospital_screen.dart';
import 'package:medical_records/screens/hospitals/department_and_doctor_screen.dart';
import 'package:medical_records/screens/treatments/treatments_screen.dart';
import 'package:medical_records/screens/settings/app_settings_screen.dart';
import 'package:medical_records/screens/settings/settings_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> key =
      GlobalKey<NavigatorState>(debugLabel: 'routerKey');

  static GoRouter router = GoRouter(
    navigatorKey: key,
    debugLogDiagnostics: true,
    initialLocation: SplashScreen.path,
    routes: routes,
    errorBuilder: (context, state) {
      return ErrorScreen(routerState: state);
    },
  );

  static List<GoRoute> routes = [
    GoRoute(
      name: SplashScreen.name,
      path: SplashScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const SplashScreen(),
        );
      },
    ),
    GoRoute(
      name: HomeScreen.name,
      path: HomeScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const HomeScreen(),
        );
      },
    ),
    GoRoute(
      name: TreatmentsScreen.name,
      path: TreatmentsScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const TreatmentsScreen(),
        );
      },
    ),
    GoRoute(
      name: HospitalsScreen.name,
      path: HospitalsScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const HospitalsScreen(),
        );
      },
      routes: [
        GoRoute(
          name: AddHospitalScreen.name,
          path: AddHospitalScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const AddHospitalScreen(),
            );
          },
        ),
        GoRoute(
          name: EditHospitalScreen.name,
          path: EditHospitalScreen.path,
          pageBuilder: (context, state) {
            final hospitalId = int.parse(state.pathParameters['id']!);

            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: EditHospitalScreen(hospitalId: hospitalId),
            );
          },
        ),
        GoRoute(
          name: DepartmentAndDoctorScreen.name,
          path: DepartmentAndDoctorScreen.path,
          pageBuilder: (context, state) {
            final hospitalId = int.parse(state.pathParameters['id']!);

            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: DepartmentAndDoctorScreen(hospitalId: hospitalId),
            );
          },
        ),
      ],
    ),
    GoRoute(
      name: SettingsScreen.name,
      path: SettingsScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const SettingsScreen(),
        );
      },
      routes: [
        GoRoute(
          name: AppSettingsScreen.name,
          path: AppSettingsScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const AppSettingsScreen(),
            );
          },
        ),
      ],
    ),
  ];
}
