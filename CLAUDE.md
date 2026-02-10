# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter monorepo for a medical records application, managed by Melos. Uses clean architecture with BLoC pattern, Drift ORM for SQLite persistence, and modular package structure. Melos configuration is embedded in the root `pubspec.yaml`.

## Development Commands

### Setup (run once)
```bash
dart pub global activate melos
dart pub global activate mason_cli
melos bootstrap
mason get
melos run prepare              # Generates code, runs build_runner, gen-l10n
```

### Daily Workflow
```bash
melos run analyze              # Static analysis (flutter analyze --fatal-infos)
melos run fix                  # Auto-fix issues
melos run format               # Format code
melos run test                 # Run all tests
melos run test:dart            # Dart-only tests
melos run test:flutter         # Flutter-only tests
melos run build-runner         # Generate code (Drift, etc.)
melos run gen-l10n             # Generate localization files
melos run brick-test           # Run Mason brick tests
```

### Running the App
```bash
flutter run                    # Default device
flutter run -d chrome          # Web
flutter run -d ios             # iOS
```

### Single Package Operations
```bash
cd app_lib/database
flutter test
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

### Monorepo Structure
```
lib/                    # Main app entry, screens, router
app_bloc/               # BLoC packages per domain entity
  ├── hospital/         # HospitalBloc, events, states
  ├── treatment/        # TreatmentBloc
  ├── visit/            # VisitBloc, VisitLocationBloc, VisitResourceBloc
  └── *_form_bloc/      # Form-specific BLoCs with validation
app_lib/                # Shared libraries
  ├── database/         # Drift ORM (SQLite)
  ├── theme/            # Theme management
  ├── locale/           # i18n with ARB files
  ├── provider/         # Dependency injection (MainProvider)
  ├── logging/          # AppLogger, CrashReportingWidget
  ├── storage/          # Resource file storage (SHA256-named)
  ├── backup/           # Export/import to ZIP archives
  └── utils/            # FieldDependencyHelper, etc.
app_widget/             # Reusable UI packages
  ├── adaptive/         # Responsive layout widgets
  ├── feedback/         # Dialogs, toasts, bottom sheets
  └── resources/        # Resource management widgets
third_party/            # Customized packages (form_bloc, settings_ui, flutter_adaptive_scaffold)
bricks/                 # Mason templates
```

### Key Files
- `lib/main.dart` - App initialization, BLoC providers setup
- `lib/router.dart` - GoRouter configuration with NoTransitionPage
- `app_lib/database/lib/src/database.dart` - Drift database with CRUD operations
- `app_lib/provider/lib/src/main.dart` - MainProvider dependency injection

### Data Flow
1. **Database** (Drift): Tables for Hospitals, Departments, Doctors, Treatments, Visits, Resources
2. **BLoC**: Each entity has events (LoadX, AddX, UpdateX, DeleteX) and states (XInitial, XLoading, XLoaded, XError)
3. **Provider**: MainProvider injects SharedPreferences and AppDatabase
4. **UI**: Screens use BlocBuilder/BlocListener, GoRouter for navigation

## Critical Patterns

### Internal Package Dependencies
**Always use workspace resolution, never path dependencies:**

```yaml
# ✅ Correct
environment:
  sdk: ">=3.8.0 <4.0.0"
  resolution: workspace

dependencies:
  app_database: any
  app_theme: any

# ❌ Wrong - never do this
dependencies:
  app_database:
    path: ../../app_lib/database
```

### Testing Patterns
```dart
// Use in-memory database for tests
final db = AppDatabase.forTesting();

// Use mocktail for mocking (preferred over mockito in this codebase)
class MockDatabase extends Mock implements AppDatabase {}

// Use bloc_test for BLoC testing
blocTest<HospitalBloc, HospitalState>(
  'emits [loading, loaded] when LoadHospitals succeeds',
  build: () => HospitalBloc(db: mockDb),
  act: (bloc) => bloc.add(LoadHospitals()),
  expect: () => [isA<HospitalLoading>(), isA<HospitalLoaded>()],
);
```

### Form Field Dependencies
Use `FieldDependencyHelper` from `app_lib/utils` to manage cascading field updates without race conditions. Avoids `Future.delayed()` hacks.

### Safe Widgets
Use `SafeDropdownFieldBlocBuilder` for form dropdowns to prevent assertion errors during state transitions.

### Resource Storage
Files stored as `<app_documents>/resources/<visitId>/<sha256sum>.<ext>`. See DATA.md for schema details.

## Code Generation

### Mason Bricks (see BRICKS.md for details)
```bash
mason make simple_bloc -o app_bloc/feature_name --name=feature_name
mason make screen --name ScreenName --folder subfolder
mason make widget --name WidgetName --type stateless
mason make form_bloc --name Login --field_names "email,password"
```

### Localization
```bash
melos run gen-l10n
# ARB files in app_lib/locale/lib/src/l10n/
# Use context.l10n.stringKey in UI
```

## Database Schema

**Hospitals** → **Departments**, **Doctors** (via hospitalId)
**Treatments** → **Visits** (via treatmentId) → **Resources** (via visitId)

See DATA.md for complete field definitions and backup/restore functionality.

## Third-Party Customizations

The `third_party/` folder contains forked packages with local modifications:
- **form_bloc** / **flutter_form_bloc**: Form state management with custom fixes
- **flutter_adaptive_scaffold**: Responsive layouts with project-specific changes
- **settings_ui**: Settings screen components

When updating these, check if upstream changes conflict with local modifications.

## Additional Documentation

- **BRICKS.md**: Mason template guide with examples
- **DATA.md**: Database schema and backup/restore format
