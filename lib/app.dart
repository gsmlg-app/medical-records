import 'package:app_locale/app_locale.dart';
import 'package:duskmoon_theme/duskmoon_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:duskmoon_theme_bloc/duskmoon_theme_bloc.dart';

import 'router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<DmThemeBloc>();

    return BlocBuilder<DmThemeBloc, DmThemeState>(
        bloc: themeBloc,
        builder: (context, state) {
          final router = AppRouter.router;
          return DuskmoonApp(
            child: MaterialApp.router(
              key: const Key('app'),
              debugShowCheckedModeBanner: false,
              routerConfig: router,
              onGenerateTitle: (context) => context.l10n.appName,
              theme: state.entry.light,
              darkTheme: state.entry.dark,
              themeMode: state.themeMode,
              localizationsDelegates: AppLocale.localizationsDelegates,
              supportedLocales: AppLocale.supportedLocales,
            ),
          );
        });
  }
}
