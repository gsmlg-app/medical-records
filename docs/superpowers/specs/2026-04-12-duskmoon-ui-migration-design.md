# DuskMoon UI Migration Design

## Overview

Migrate the medical-records Flutter app from four forked third-party packages to the DuskMoon UI design system (`duskmoon_ui` umbrella). After migration, the following directories are removed:

- `third_party/form_bloc/`
- `third_party/flutter_form_bloc/`
- `third_party/settings_ui/`
- `third_party/flutter_adaptive_scaffold/`

Additionally, `app_bloc/theme/` is removed (replaced by `duskmoon_theme_bloc`).

## Approach

Incremental package-by-package migration in dependency order. Each phase produces a working, testable state.

## Phase 1: Theme Migration

### What changes

- **Remove** `app_bloc/theme/` package entirely
- **Remove** `app_lib/theme/` custom theme classes (`AppThemes`, `ThemeBloc`, `ThemeState`, `ThemeModeExtension`)
- **Add** `duskmoon_theme: ^1.4.0` and `duskmoon_theme_bloc: ^1.4.0` as workspace dependencies
- **Replace** all `ThemeBloc` usage with `DmThemeBloc`
- **Replace** all `ThemeState` usage with `DmThemeState`
- **Replace** events: `ChangeTheme` -> `DmSetTheme`, `ChangeThemeMode` -> `DmSetThemeMode`
- **Replace** `ThemeModeExtension` with the one from `duskmoon_theme`

### Theme mapping

Drop the current Violet/Green/Fire/Wheat seed-color themes. Use DuskMoon's built-in presets:
- Default light: `DmThemeData.sunshine()`
- Default dark: `DmThemeData.moonlight()`
- Additional themes available via `DmThemeData.themes` (duskmoon + ecotone families)

### Key file changes

| File | Change |
|------|--------|
| `lib/app.dart` | `BlocBuilder<DmThemeBloc, DmThemeState>`, use `state.entry.light`/`state.entry.dark`, `state.themeMode` |
| `lib/main.dart` | Replace `ThemeBloc` provider with `DmThemeBloc(prefs: prefs)` |
| `lib/screens/settings/appearance_settings_screen.dart` | Use `DmSetThemeMode`, `ThemeMode.title`/`.icon` from duskmoon |
| `lib/screens/settings/accent_color_settings_screen.dart` | Use `DmThemeData.themes` iteration, `DmSetTheme` |
| All screens importing `ThemeBloc` | Update imports |

### Packages removed

- `app_bloc/theme/`
- `app_lib/theme/` (or reduced to re-export if other packages depend on it for non-theme utilities)

## Phase 2: Adaptive Scaffold Migration

### What changes

- **Replace** `flutter_adaptive_scaffold` dependency with `duskmoon_adaptive_scaffold: ^1.4.0`
- **Update** `app_widget/adaptive/` to use `DmAdaptiveScaffold` instead of `AdaptiveScaffold`
- **Update** import paths from `package:flutter_adaptive_scaffold/...` to `package:duskmoon_adaptive_scaffold/...`
- `Breakpoints` class, `NavigationDestination`, `SlotLayout`, `AdaptiveLayout` all available from duskmoon with same API

### Key file changes

| File | Change |
|------|--------|
| `app_widget/adaptive/pubspec.yaml` | Replace dependency |
| `app_widget/adaptive/lib/` | Update imports, use `DmAdaptiveScaffold` |
| `destination.dart` | No changes needed (uses Flutter core types) |
| All screens using `AppAdaptiveScaffold` | No changes if wrapper is updated |

### Packages removed

- `third_party/flutter_adaptive_scaffold/`

## Phase 3: Feedback Migration

### What changes

- **Replace** `app_widget/feedback/` internals with `duskmoon_feedback: ^1.4.0`
- Either re-export from `duskmoon_feedback` or update all callers to import directly

### API mapping

| Current | DuskMoon |
|---------|----------|
| `showAppDialog<T>()` | `showDmDialog<T>()` |
| `AppDialogAction` | `DmDialogAction` |
| `showSnackbar()` | `showDmSnackbar()` |
| `showUndoSnackbar()` | `showDmUndoSnackbar()` |
| `showSuccessToast()` | `showDmSuccessToast()` |
| `showErrorToast()` | `showDmErrorToast()` |
| `showBottomSheetActionList()` | `showDmBottomSheetActionList()` |
| `BottomSheetAction` | `DmBottomSheetAction` |
| `showFullScreenDialog()` | `showDmFullscreenDialog()` |

### Parameter differences

- `showDmSuccessToast` / `showDmErrorToast`: `message` is `String` (not `Widget`)
- `showDmSnackbar` / `showDmUndoSnackbar`: `message` is `Widget`
- `showDmErrorToast`: always persistent (no duration param), always shows close icon

### Key file changes

All screens that call feedback functions need updated function names. Approximately 10-15 call sites across treatment, visit, hospital, and settings screens.

## Phase 4: Settings Migration

### What changes

- **Replace** `settings_ui` dependency with `duskmoon_settings: ^1.4.0`
- Same widget API: `SettingsList`, `SettingsSection`, `SettingsTile`, `CustomSettingsTile`
- Same named constructors: `.navigation()`, `.switchTile()`, `.checkTile()`
- New constructors available: `.input()`, `.slider()`, `.select()`, `.radioGroup()`, `.checkboxGroup()`
- Import path: `package:settings_ui/settings_ui.dart` -> `package:duskmoon_settings/duskmoon_settings.dart`

### Key file changes

| File | Change |
|------|--------|
| `lib/screens/settings/settings_screen.dart` | Update import |
| `lib/screens/settings/appearance_settings_screen.dart` | Update import, can use `SettingsTile.select()` for theme mode |
| Any package depending on `settings_ui` | Update pubspec + imports |

### Packages removed

- `third_party/settings_ui/`

## Phase 5: Forms Migration

### What changes

- **Replace** `form_bloc` + `flutter_form_bloc` with `duskmoon_form: ^1.4.0`
- BLoC classes keep same names: `FormBloc`, `TextFieldBloc`, `SelectFieldBloc`, `InputFieldBloc`, `BooleanFieldBloc`, `MultiSelectFieldBloc`, `GroupFieldBloc`, `ListFieldBloc`
- UI builders get `Dm` prefix:
  - `TextFieldBlocBuilder` -> `DmTextFieldBlocBuilder`
  - `DropdownFieldBlocBuilder` -> `DmDropdownFieldBlocBuilder`
  - `DateTimeFieldBlocBuilder` -> `DmDateTimeFieldBlocBuilder`
  - `FormBlocListener` -> `DmFormBlocListener`
  - `FormThemeProvider` -> `DmFormThemeProvider`
- `SafeDropdownFieldBlocBuilder` in `app_lib/utils` wraps `DmDropdownFieldBlocBuilder`

### Key file changes

| File/Package | Change |
|------|--------|
| `app_widget/visit_form/` | Update widget builders to Dm-prefixed, update imports |
| `app_widget/hospital_form/` | Update if using form_bloc widgets |
| `app_bloc/*_form_bloc/` packages | Update imports from `package:form_bloc/...` to `package:duskmoon_form/...` |
| `app_lib/utils/` | Update `SafeDropdownFieldBlocBuilder` |

### Packages removed

- `third_party/form_bloc/`
- `third_party/flutter_form_bloc/`

## Phase 6: Cleanup

### Workspace changes

- Remove `third_party/form_bloc`, `third_party/flutter_form_bloc`, `third_party/settings_ui`, `third_party/flutter_adaptive_scaffold` from Melos workspace in root `pubspec.yaml`
- Remove `app_bloc/theme` from Melos workspace
- Add `duskmoon_ui: ^1.4.0` to root workspace dependency overrides (or individual packages as needed)
- Run `melos bootstrap`
- Run `melos run analyze` -- must pass with zero issues
- Run `melos run test` -- all tests must pass
- Delete the four `third_party/` directories
- Delete `app_bloc/theme/` directory

### Dependency summary

Packages added (via workspace resolution):
- `duskmoon_ui: ^1.4.0` (umbrella, or individual packages)
- `duskmoon_theme: ^1.4.0`
- `duskmoon_theme_bloc: ^1.4.0`
- `duskmoon_widgets: ^1.4.0`
- `duskmoon_settings: ^1.4.0`
- `duskmoon_feedback: ^1.4.0`
- `duskmoon_form: ^1.4.0`
- `duskmoon_adaptive_scaffold: ^1.4.0`

Packages removed:
- `form_bloc` (third_party fork)
- `flutter_form_bloc` (third_party fork)
- `settings_ui` (third_party fork)
- `flutter_adaptive_scaffold` (third_party fork)
- `app_theme` (custom)
- `app_theme_bloc` (custom, in app_bloc/theme)

## Risk Assessment

- **Low risk:** Theme, scaffold, settings, feedback -- mostly import path changes with compatible APIs
- **Medium risk:** Forms -- largest surface area, most call sites, parameter differences between form_bloc and duskmoon_form field builders
- **Mitigation:** Each phase is independently testable; run `melos run analyze` and `melos run test` after each phase

## Out of Scope

- Adding new DuskMoon features not present in current app (visualization, code editor, markdown)
- Changing app architecture or navigation structure
- Adding platform-adaptive rendering (Cupertino/Fluent) -- current app is Material-only
- Updating `app_widget/resources/` or `app_widget/artwork/` packages
