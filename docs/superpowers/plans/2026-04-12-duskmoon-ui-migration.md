# DuskMoon UI Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace four third-party forks and custom theme with DuskMoon UI packages.

**Architecture:** Incremental migration in dependency order: theme -> scaffold -> feedback -> settings -> forms -> cleanup. Each task produces a compilable, testable state.

**Tech Stack:** Flutter, DuskMoon UI ^1.4.0, BLoC ^9.0.0, Melos workspace

---

## File Structure

### Files to delete (after all tasks)
- `app_bloc/theme/` (entire directory)
- `app_lib/theme/` (entire directory)
- `third_party/flutter_adaptive_scaffold/` (entire directory)
- `third_party/settings_ui/` (entire directory)
- `third_party/form_bloc/` (entire directory)
- `third_party/flutter_form_bloc/` (entire directory)

### Files to modify
- `pubspec.yaml` (root) — workspace list, dependencies
- `app_lib/provider/pubspec.yaml` — remove theme_bloc dep
- `app_lib/provider/lib/src/main.dart` — use DmThemeBloc
- `lib/main.dart` — use DmThemeBloc
- `lib/app.dart` — use DmThemeBloc/DmThemeState
- `lib/screens/settings/settings_screen.dart` — DmThemeBloc + duskmoon_settings
- `lib/screens/settings/appearance_settings_screen.dart` — DmThemeBloc + duskmoon_settings
- `lib/screens/settings/accent_color_settings_screen.dart` — DmThemeBloc + duskmoon_settings
- `lib/screens/settings/data_export_screen.dart` — adaptive import
- `lib/screens/settings/data_import_screen.dart` — adaptive import
- `lib/screens/home/home_screen.dart` — adaptive import
- `lib/screens/treatments/treatments_screen.dart` — adaptive import
- `lib/screens/treatments/treatment_detail_screen.dart` — adaptive import
- `lib/screens/treatments/add_treatment_screen.dart` — adaptive import
- `lib/screens/treatments/edit_treatment_screen.dart` — adaptive import
- `lib/screens/hospitals/hospitals_screen.dart` — adaptive import
- `lib/screens/hospitals/add_hospital_screen.dart` — adaptive import
- `lib/screens/hospitals/edit_hospital_screen.dart` — adaptive import
- `lib/screens/visits/visit_detail_screen.dart` — adaptive import
- `lib/screens/visits/add_visit_screen.dart` — adaptive + form imports
- `lib/screens/visits/edit_visit_screen.dart` — adaptive + form imports
- `app_widget/adaptive/pubspec.yaml` — swap dependency
- `app_widget/adaptive/lib/app_adaptive_widgets.dart` — update exports
- `app_widget/adaptive/lib/src/scaffold.dart` — use DmAdaptiveScaffold
- `app_widget/adaptive/lib/src/action.dart` — update export
- `app_widget/feedback/pubspec.yaml` — add duskmoon_feedback dep
- `app_widget/feedback/lib/app_feedback.dart` — re-export duskmoon_feedback
- `app_widget/feedback/lib/src/dialog.dart` — delegate to showDmDialog
- `app_widget/feedback/lib/src/snackbar.dart` — delegate to showDmSnackbar
- `app_widget/feedback/lib/src/toast.dart` — delegate to showDmSuccessToast/showDmErrorToast
- `app_widget/feedback/lib/src/bottom_sheet_action.dart` — delegate to showDmBottomSheetActionList
- `app_widget/feedback/lib/src/fullscreen_dialog.dart` — delegate to showDmFullscreenDialog
- `app_widget/visit_form/pubspec.yaml` — swap form_bloc deps
- `app_widget/visit_form/lib/visit_form.dart` — use duskmoon_form widgets
- `app_widget/visit_form/lib/safe_dropdown_field_bloc_builder.dart` — use duskmoon_form
- `app_widget/visit_form/lib/resources_section_wrapper.dart` — update import
- `app_bloc/visit_form_bloc/pubspec.yaml` — swap form_bloc dep
- `app_bloc/visit_form_bloc/lib/src/bloc.dart` — update import
- `bricks/screen/__brick__/lib/screens/{{#folder}}{{folder}}/{{/folder}}{{name.snakeCase()}}_screen.dart` — update adaptive import

---

### Task 1: Add duskmoon_ui to workspace and update root pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Update workspace list — remove old entries, keep the rest**

In `pubspec.yaml`, remove these workspace entries:
```
  - app_lib/theme
  - app_bloc/theme
  - third_party/form_bloc
  - third_party/flutter_form_bloc
  - third_party/flutter_adaptive_scaffold
  - third_party/settings_ui
```

- [ ] **Step 2: Update dependencies — remove old, add new**

In `pubspec.yaml` dependencies section:

Remove:
```yaml
  google_fonts: ^6.2.1
  app_theme: any
  theme_bloc: any
  settings_ui: any
```

Add:
```yaml
  duskmoon_ui: ^1.4.0
  duskmoon_theme: ^1.4.0
  duskmoon_theme_bloc: ^1.4.0
  duskmoon_settings: ^1.4.0
  duskmoon_feedback: ^1.4.0
  duskmoon_form: ^1.4.0
  duskmoon_adaptive_scaffold: ^1.4.0
  duskmoon_widgets: ^1.4.0
```

Remove from dev_dependencies:
```yaml
  # form_bloc: ^1.11.0 # Using workspace version instead
```

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml
git commit -m "chore: update workspace for duskmoon_ui migration"
```

---

### Task 2: Migrate theme system (DmThemeBloc replaces ThemeBloc)

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/app.dart`
- Modify: `app_lib/provider/pubspec.yaml`
- Modify: `app_lib/provider/lib/src/main.dart`

- [ ] **Step 1: Update app_lib/provider/pubspec.yaml**

Replace `theme_bloc: any` with `duskmoon_theme_bloc: ^1.4.0`:

```yaml
dependencies:
  bloc: ^9.0.0
  flutter_bloc: ^9.0.0
  equatable: ^2.0.5
  flutter:
    sdk: flutter
  shared_preferences: ^2.0.17

  duskmoon_theme_bloc: ^1.4.0
  app_database: any
  treatment_bloc: any
  visit_bloc: any
```

- [ ] **Step 2: Update app_lib/provider/lib/src/main.dart**

Replace:
```dart
import 'package:theme_bloc/theme_bloc.dart';
```
With:
```dart
import 'package:duskmoon_theme_bloc/duskmoon_theme_bloc.dart';
```

Replace:
```dart
BlocProvider<ThemeBloc>(
  create: (BuildContext context) => ThemeBloc(
    context.read<SharedPreferences>(),
  ),
),
```
With:
```dart
BlocProvider<DmThemeBloc>(
  create: (BuildContext context) => DmThemeBloc(
    prefs: context.read<SharedPreferences>(),
  ),
),
```

- [ ] **Step 3: Update lib/main.dart**

Replace:
```dart
import 'package:theme_bloc/theme_bloc.dart';
```
With:
```dart
import 'package:duskmoon_theme_bloc/duskmoon_theme_bloc.dart';
```

Replace:
```dart
BlocProvider(create: (context) => ThemeBloc(sharedPrefs)),
```
With:
```dart
BlocProvider(create: (context) => DmThemeBloc(prefs: sharedPrefs)),
```

- [ ] **Step 4: Update lib/app.dart**

Replace entire file content:
```dart
import 'package:app_locale/app_locale.dart';
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
  bool isOpenWindow = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<DmThemeBloc>();

    return BlocBuilder<DmThemeBloc, DmThemeState>(
        bloc: themeBloc,
        builder: (context, state) {
          final router = AppRouter.router;
          final entry = state.entry;
          return MaterialApp.router(
            key: const Key('app'),
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            onGenerateTitle: (context) => context.l10n.appName,
            theme: entry.light,
            darkTheme: entry.dark,
            themeMode: state.themeMode,
            localizationsDelegates: AppLocale.localizationsDelegates,
            supportedLocales: AppLocale.supportedLocales,
          );
        });
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/app.dart app_lib/provider/
git commit -m "feat: migrate theme system to DmThemeBloc"
```

---

### Task 3: Migrate adaptive scaffold

**Files:**
- Modify: `app_widget/adaptive/pubspec.yaml`
- Modify: `app_widget/adaptive/lib/app_adaptive_widgets.dart`
- Modify: `app_widget/adaptive/lib/src/scaffold.dart`
- Modify: `app_widget/adaptive/lib/src/action.dart`

- [ ] **Step 1: Update app_widget/adaptive/pubspec.yaml**

Replace `flutter_adaptive_scaffold: any` with `duskmoon_adaptive_scaffold: ^1.4.0`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

  duskmoon_adaptive_scaffold: ^1.4.0
  flutter_bloc: ^9.0.0
```

- [ ] **Step 2: Update app_widget/adaptive/lib/src/scaffold.dart**

Replace:
```dart
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

export 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
```
With:
```dart
import 'package:duskmoon_adaptive_scaffold/duskmoon_adaptive_scaffold.dart';

export 'package:duskmoon_adaptive_scaffold/duskmoon_adaptive_scaffold.dart';
```

Replace in the `build` method:
```dart
return AdaptiveScaffold(
```
With:
```dart
return DmAdaptiveScaffold(
```

- [ ] **Step 3: Update app_widget/adaptive/lib/src/action.dart**

Replace:
```dart
export 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
```
With:
```dart
export 'package:duskmoon_adaptive_scaffold/duskmoon_adaptive_scaffold.dart';
```

- [ ] **Step 4: Update settings_screen.dart — replace AdaptiveScaffold.emptyBuilder**

In `lib/screens/settings/settings_screen.dart`, `lib/screens/settings/appearance_settings_screen.dart`, `lib/screens/settings/accent_color_settings_screen.dart`:

Replace any occurrence of:
```dart
smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
```
With:
```dart
smallSecondaryBody: DmAdaptiveScaffold.emptyBuilder,
```

Note: This reference comes from the re-export in `app_adaptive_widgets`. Since `AdaptiveScaffold` is no longer exported, all references must use `DmAdaptiveScaffold`. Search all screen files for `AdaptiveScaffold.emptyBuilder` and replace.

- [ ] **Step 5: Update the mason brick template**

In `bricks/screen/__brick__/lib/screens/{{#folder}}{{folder}}/{{/folder}}{{name.snakeCase()}}_screen.dart`, if it references `flutter_adaptive_scaffold`, update the import to use `app_adaptive_widgets` (it should already, but verify).

- [ ] **Step 6: Commit**

```bash
git add app_widget/adaptive/ lib/screens/ bricks/
git commit -m "feat: migrate adaptive scaffold to duskmoon_adaptive_scaffold"
```

---

### Task 4: Migrate feedback widgets

**Files:**
- Modify: `app_widget/feedback/pubspec.yaml`
- Modify: `app_widget/feedback/lib/app_feedback.dart`
- Modify: `app_widget/feedback/lib/src/dialog.dart`
- Modify: `app_widget/feedback/lib/src/snackbar.dart`
- Modify: `app_widget/feedback/lib/src/toast.dart`
- Modify: `app_widget/feedback/lib/src/bottom_sheet_action.dart`
- Modify: `app_widget/feedback/lib/src/fullscreen_dialog.dart`
- Modify: `app_widget/feedback/lib/src/helper.dart`

- [ ] **Step 1: Update app_widget/feedback/pubspec.yaml**

Add `duskmoon_feedback`:
```yaml
dependencies:
  flutter:
    sdk: flutter

  app_locale: any
  duskmoon_feedback: ^1.4.0
```

- [ ] **Step 2: Replace app_widget/feedback/lib/app_feedback.dart**

Replace with re-exports from duskmoon_feedback plus any app-specific helpers:
```dart
library;

// Re-export all DuskMoon feedback functions
export 'package:duskmoon_feedback/duskmoon_feedback.dart';

// Keep app-specific helpers if any
export 'src/helper.dart';
```

- [ ] **Step 3: Replace dialog.dart**

Replace the entire content of `app_widget/feedback/lib/src/dialog.dart` with a re-export or delegation. Since callers will use the duskmoon exports directly from the barrel file, this file can be emptied or removed. The simplest approach: delete the file's contents and remove its export from the barrel.

Actually, since `app_feedback.dart` now re-exports `duskmoon_feedback`, the individual src files can be deleted. Remove from the barrel:
- `src/bottom_sheet_action.dart`
- `src/dialog.dart`
- `src/fullscreen_dialog.dart`
- `src/snackbar.dart`
- `src/toast.dart`

Keep `src/helper.dart` if it has app-specific logic (check its contents).

- [ ] **Step 4: Update callers — check for parameter differences**

Search for all call sites of `showSuccessToast` and `showErrorToast`. In duskmoon_feedback:
- `showDmSuccessToast(context: context, message: 'string')` — message is `String`, not `Widget`
- `showDmErrorToast(context: context, message: 'string')` — message is `String`
- `showDmSnackbar(context: context, message: Text('...'))` — message is `Widget`
- `showDmUndoSnackbar(context: context, message: Text('...'), onUndoPressed: () {})` — message is `Widget`

Update any call sites in the app that pass `Widget` to toast functions or `String` to snackbar functions.

- [ ] **Step 5: Commit**

```bash
git add app_widget/feedback/
git commit -m "feat: migrate feedback widgets to duskmoon_feedback"
```

---

### Task 5: Migrate settings screens

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`
- Modify: `lib/screens/settings/appearance_settings_screen.dart`
- Modify: `lib/screens/settings/accent_color_settings_screen.dart`

- [ ] **Step 1: Update settings_screen.dart**

Replace imports:
```dart
import 'package:app_theme/app_theme.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:theme_bloc/theme_bloc.dart';
```
With:
```dart
import 'package:duskmoon_settings/duskmoon_settings.dart';
import 'package:duskmoon_theme/duskmoon_theme.dart';
import 'package:duskmoon_theme_bloc/duskmoon_theme_bloc.dart';
```

Replace all `ThemeBloc` with `DmThemeBloc`, `ThemeState` with `DmThemeState`:
```dart
final themeBloc = context.read<DmThemeBloc>();
```
```dart
BlocBuilder<DmThemeBloc, DmThemeState>(
```

Replace `state.theme.name` with `state.themeName`:
```dart
value: Text(state.themeName),
```

Replace `state.themeMode.icon` with `state.themeMode.icon` (same API from duskmoon_theme's ThemeModeExtension).

- [ ] **Step 2: Update appearance_settings_screen.dart**

Replace imports:
```dart
import 'package:settings_ui/settings_ui.dart';
import 'package:theme_bloc/theme_bloc.dart';
```
With:
```dart
import 'package:duskmoon_settings/duskmoon_settings.dart';
import 'package:duskmoon_theme_bloc/duskmoon_theme_bloc.dart';
```

Replace `ThemeBloc` -> `DmThemeBloc`, `ThemeState` -> `DmThemeState`.

Replace:
```dart
themeBloc.add(const ChangeThemeMode(ThemeMode.light));
```
With:
```dart
themeBloc.add(const DmSetThemeMode(ThemeMode.light));
```

Same for `ThemeMode.dark` and `ThemeMode.system`.

Replace `AdaptiveScaffold.emptyBuilder` with `DmAdaptiveScaffold.emptyBuilder` (if not done in Task 3).

- [ ] **Step 3: Update accent_color_settings_screen.dart**

Replace imports:
```dart
import 'package:app_theme/app_theme.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:theme_bloc/theme_bloc.dart';
```
With:
```dart
import 'package:duskmoon_settings/duskmoon_settings.dart';
import 'package:duskmoon_theme/duskmoon_theme.dart';
import 'package:duskmoon_theme_bloc/duskmoon_theme_bloc.dart';
```

Replace `ThemeBloc` -> `DmThemeBloc`, `ThemeState` -> `DmThemeState`.

Replace theme iteration — `themeList` is no longer available. Use `DmThemeData.themes`:
```dart
tiles: DmThemeData.themes.map<SettingsTile>((themeEntry) {
  final isSelected = state.themeName == themeEntry.name;
  final colorScheme = isLight
      ? themeEntry.light.colorScheme
      : themeEntry.dark.colorScheme;

  return SettingsTile(
    leading: Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
    ),
    title: Text(themeEntry.name),
    trailing: isSelected ? const Icon(Icons.check) : null,
    value: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
          ),
        ),
        Container(
          width: 16,
          height: 16,
          color: colorScheme.secondary,
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: colorScheme.tertiary,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
        ),
      ],
    ),
    onPressed: (context) {
      themeBloc.add(DmSetTheme(themeEntry.name));
    },
  );
}).toList(),
```

Key changes:
- `themeList` -> `DmThemeData.themes`
- `currentTheme.name == appTheme.name` -> `state.themeName == themeEntry.name`
- `appTheme.lightTheme` -> `themeEntry.light`
- `appTheme.darkTheme` -> `themeEntry.dark`
- `ChangeTheme(appTheme)` -> `DmSetTheme(themeEntry.name)`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/settings/
git commit -m "feat: migrate settings screens to duskmoon_settings and DmThemeBloc"
```

---

### Task 6: Migrate form packages

**Files:**
- Modify: `app_bloc/visit_form_bloc/pubspec.yaml`
- Modify: `app_bloc/visit_form_bloc/lib/src/bloc.dart`
- Modify: `app_widget/visit_form/pubspec.yaml`
- Modify: `app_widget/visit_form/lib/visit_form.dart`
- Modify: `app_widget/visit_form/lib/safe_dropdown_field_bloc_builder.dart`
- Modify: `app_widget/visit_form/lib/resources_section_wrapper.dart`
- Modify: `lib/screens/visits/add_visit_screen.dart`
- Modify: `lib/screens/visits/edit_visit_screen.dart`

- [ ] **Step 1: Update app_bloc/visit_form_bloc/pubspec.yaml**

Replace the path dependency:
```yaml
  form_bloc:
    path: ../../third_party/form_bloc
```
With workspace resolution:
```yaml
  duskmoon_form: ^1.4.0
```

- [ ] **Step 2: Update app_bloc/visit_form_bloc/lib/src/bloc.dart**

Replace:
```dart
import 'package:form_bloc/form_bloc.dart';
```
With:
```dart
import 'package:duskmoon_form/duskmoon_form.dart';
```

The `FormBloc`, `TextFieldBloc`, `SelectFieldBloc`, `InputFieldBloc` class names are the same in `duskmoon_form`. No other changes needed in this file.

- [ ] **Step 3: Update app_widget/visit_form/pubspec.yaml**

Replace:
```yaml
  flutter_form_bloc:
    path: ../../third_party/flutter_form_bloc
  form_bloc:
    path: ../../third_party/form_bloc
```
With:
```yaml
  duskmoon_form: ^1.4.0
```

Also update other path deps to workspace resolution:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.0.0
  duskmoon_form: ^1.4.0
  app_locale: any
  app_logging: any
  app_database: any
  app_resources: any
  visit_form_bloc: any
  hospital_bloc: any
  hospital_form_bloc: any
  hospital_form: any
```

- [ ] **Step 4: Update app_widget/visit_form/lib/visit_form.dart**

Replace:
```dart
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
```
With:
```dart
import 'package:duskmoon_form/duskmoon_form.dart';
```

Replace widget references:
- `FormThemeProvider` -> `DmFormThemeProvider`
- `FormTheme` -> `DmFormTheme`
- `DropdownFieldBlocBuilder` -> `DmDropdownFieldBlocBuilder`
- `DateTimeFieldBlocBuilder` -> `DmDateTimeFieldBlocBuilder`
- `TextFieldBlocBuilder` -> `DmTextFieldBlocBuilder`
- `FormBlocState` stays the same
- `FormBlocSuccess` stays the same
- `FormBlocFailure` stays the same
- `FormBlocLoading` stays the same
- `FieldItem` stays the same

Specifically in the build method:
```dart
return DmFormThemeProvider(
  theme: DmFormTheme(
    textTheme: TextFieldTheme(
      decorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
  ),
  child: Form(
    // ...
    children: [
      DmDropdownFieldBlocBuilder<VisitCategory>(
        selectFieldBloc: visitFormBloc.categoryFieldBloc,
        decoration: InputDecoration(
          labelText: context.l10n.visitCategory,
        ),
        itemBuilder: (context, value) =>
            FieldItem(child: Text(_formatCategoryName(value))),
      ),
      // ...
      DmDateTimeFieldBlocBuilder(
        dateTimeFieldBloc: visitFormBloc.dateFieldBloc,
        format: DateFormat('yyyy-MM-dd'),
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        decoration: InputDecoration(
          labelText: context.l10n.visitDate,
        ),
      ),
      // ...
      DmTextFieldBlocBuilder(
        textFieldBloc: visitFormBloc.detailsFieldBloc,
        decoration: InputDecoration(
          labelText: context.l10n.visitDetails,
          hintText: 'Enter optional visit details...',
        ),
        maxLines: 3,
      ),
    ],
  ),
);
```

- [ ] **Step 5: Update app_widget/visit_form/lib/safe_dropdown_field_bloc_builder.dart**

Replace:
```dart
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
```
With:
```dart
import 'package:duskmoon_form/duskmoon_form.dart';
```

The `SelectFieldBloc`, `SelectFieldBlocState`, `BlocBuilder` types are the same. No other changes needed.

- [ ] **Step 6: Update app_widget/visit_form/lib/resources_section_wrapper.dart**

Replace:
```dart
import 'package:form_bloc/form_bloc.dart';
```
With:
```dart
import 'package:duskmoon_form/duskmoon_form.dart';
```

- [ ] **Step 7: Update visit screen files**

In `lib/screens/visits/edit_visit_screen.dart`, replace:
```dart
import 'package:form_bloc/form_bloc.dart';
```
With:
```dart
import 'package:duskmoon_form/duskmoon_form.dart';
```

In `lib/screens/visits/add_visit_screen.dart`, check for any `form_bloc` or `flutter_form_bloc` imports and replace similarly.

- [ ] **Step 8: Update test files**

In `app_bloc/visit_form_bloc/test/visit_form_bloc_test.dart` and `test/visit_form_bloc_test.dart`, replace:
```dart
import 'package:form_bloc/form_bloc.dart';
```
With:
```dart
import 'package:duskmoon_form/duskmoon_form.dart';
```

- [ ] **Step 9: Commit**

```bash
git add app_bloc/visit_form_bloc/ app_widget/visit_form/ lib/screens/visits/ test/
git commit -m "feat: migrate form system to duskmoon_form"
```

---

### Task 7: Delete old packages and clean up workspace

**Files:**
- Delete: `app_bloc/theme/` (entire directory)
- Delete: `app_lib/theme/` (entire directory)
- Delete: `third_party/flutter_adaptive_scaffold/` (entire directory)
- Delete: `third_party/settings_ui/` (entire directory)
- Delete: `third_party/form_bloc/` (entire directory)
- Delete: `third_party/flutter_form_bloc/` (entire directory)

- [ ] **Step 1: Delete the directories**

```bash
rm -rf app_bloc/theme/
rm -rf app_lib/theme/
rm -rf third_party/flutter_adaptive_scaffold/
rm -rf third_party/settings_ui/
rm -rf third_party/form_bloc/
rm -rf third_party/flutter_form_bloc/
rm -rf app_bloc/visit_form_bloc_refactored/  # Dead code, not in workspace
```

- [ ] **Step 2: Check for any remaining references**

Search for any stale imports:
```bash
grep -r "package:app_theme" --include="*.dart" lib/ app_bloc/ app_lib/ app_widget/
grep -r "package:theme_bloc" --include="*.dart" lib/ app_bloc/ app_lib/ app_widget/
grep -r "package:settings_ui" --include="*.dart" lib/ app_bloc/ app_lib/ app_widget/
grep -r "package:flutter_adaptive_scaffold" --include="*.dart" lib/ app_bloc/ app_lib/ app_widget/
grep -r "package:form_bloc/" --include="*.dart" lib/ app_bloc/ app_lib/ app_widget/
grep -r "package:flutter_form_bloc" --include="*.dart" lib/ app_bloc/ app_lib/ app_widget/
```

Fix any remaining references found.

- [ ] **Step 3: Check for stale pubspec references**

```bash
grep -r "app_theme\|theme_bloc\|settings_ui\|flutter_adaptive_scaffold" --include="pubspec.yaml" .
```

Fix any remaining references (should be none after previous tasks).

- [ ] **Step 4: Also remove the third_party directory if empty**

```bash
rmdir third_party/ 2>/dev/null || true
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: remove old third-party forks and custom theme packages"
```

---

### Task 8: Bootstrap and verify

- [ ] **Step 1: Run melos bootstrap**

```bash
melos bootstrap
```

Expected: All packages resolve successfully. If there are dependency conflicts, fix pubspec.yaml files and re-run.

- [ ] **Step 2: Run analysis**

```bash
melos run analyze
```

Expected: Zero errors, zero warnings. Fix any issues found.

- [ ] **Step 3: Run tests**

```bash
melos run test
```

Expected: All tests pass. Fix any failures.

- [ ] **Step 4: Run the app**

```bash
flutter run -d chrome
```

Verify:
1. App launches with DuskMoon theme (sunshine/moonlight)
2. Navigation works (bottom nav on mobile, rail on desktop)
3. Settings > Appearance switches between light/dark/system
4. Settings > Accent Color shows duskmoon theme options
5. Add/edit visit form works with dropdowns and date picker
6. Add hospital form works

- [ ] **Step 5: Commit any fixes**

```bash
git add -A
git commit -m "fix: resolve post-migration issues"
```

---

### Task 9: Update mason brick templates

**Files:**
- Modify: `bricks/form_bloc/__brick__/pubspec.yaml` (if it references form_bloc/flutter_form_bloc)

- [ ] **Step 1: Update form_bloc brick template**

In `bricks/form_bloc/__brick__/pubspec.yaml`, replace:
```yaml
  form_bloc: any
  flutter_form_bloc: any
```
With:
```yaml
  duskmoon_form: ^1.4.0
```

- [ ] **Step 2: Check other brick templates for stale imports**

```bash
grep -r "form_bloc\|flutter_form_bloc\|settings_ui\|flutter_adaptive_scaffold\|app_theme\|theme_bloc" bricks/ --include="*.dart" --include="*.yaml"
```

Fix any references found.

- [ ] **Step 3: Commit**

```bash
git add bricks/
git commit -m "chore: update mason brick templates for duskmoon_ui"
```

---

### Task 10: Final cleanup and refactored code review

- [ ] **Step 1: Remove google_fonts if no longer used**

Check if `google_fonts` is still imported anywhere:
```bash
grep -r "package:google_fonts" --include="*.dart" .
```

If not used, it was already removed from root pubspec in Task 1.

- [ ] **Step 2: Run full verification suite**

```bash
melos bootstrap
melos run analyze
melos run format
melos run test
```

All must pass cleanly.

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "chore: finalize duskmoon_ui migration"
```
