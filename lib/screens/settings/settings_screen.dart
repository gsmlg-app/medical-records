import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:medical_records/destination.dart';
import 'package:medical_records/screens/settings/accent_color_settings_screen.dart';
import 'package:medical_records/screens/settings/appearance_settings_screen.dart';
import 'package:medical_records/screens/settings/data_export_screen.dart';
import 'package:medical_records/screens/settings/data_import_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:duskmoon_settings/duskmoon_settings.dart';
import 'package:duskmoon_theme/duskmoon_theme.dart';
import 'package:duskmoon_theme_bloc/duskmoon_theme_bloc.dart';

class SettingsScreen extends StatelessWidget {
  static const name = 'Settings';
  static const path = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(const Key(name), context),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(
        idx,
        context,
      ),
      destinations: Destinations.navs(context),
      body: (context) {
        final themeBloc = context.read<DmThemeBloc>();

        return SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                title: Text(context.l10n.settingsTitle),
              ),
              SliverFillRemaining(
                child: BlocBuilder<DmThemeBloc, DmThemeState>(
                  bloc: themeBloc,
                  builder: (context, state) {
                    return SettingsList(
                      sections: [
                        SettingsSection(
                          title: const Text('Data Management'),
                          tiles: <SettingsTile>[
                            SettingsTile.navigation(
                              leading: const Icon(Icons.download),
                              title: const Text('Export Data'),
                              description: const Text('Export treatments to a zip file'),
                              onPressed: (context) {
                                context.goNamed(DataExportScreen.name);
                              },
                            ),
                            SettingsTile.navigation(
                              leading: const Icon(Icons.upload),
                              title: const Text('Import Data'),
                              description: const Text('Import treatments from a zip file'),
                              onPressed: (context) {
                                context.goNamed(DataImportScreen.name);
                              },
                            ),
                          ],
                        ),
                        SettingsSection(
                          title: Text(context.l10n.smenuTheme),
                          tiles: <SettingsTile>[
                            SettingsTile.navigation(
                              leading: const Icon(Icons.brightness_medium),
                              title: Text(context.l10n.appearance),
                              value: state.themeMode.icon,
                              onPressed: (context) {
                                context.goNamed(AppearanceSettingsScreen.name);
                              },
                            ),
                            SettingsTile.navigation(
                              leading: const Icon(Icons.palette),
                              title: Text(context.l10n.accentColor),
                              value: Text(state.themeName),
                              onPressed: (context) {
                                context.goNamed(AccentColorSettingsScreen.name);
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      smallSecondaryBody: DmAdaptiveScaffold.emptyBuilder,
    );
  }
}
