import 'package:flutter/material.dart';
import 'package:medical_records/screens/app/error_screen.dart';
import 'package:medical_records/screens/app/splash_screen.dart';
import 'package:medical_records/screens/home/home_screen.dart';
import 'package:medical_records/screens/hospitals/hospitals_screen.dart';
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
