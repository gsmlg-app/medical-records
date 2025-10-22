# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter monorepo managed by Melos, providing a comprehensive medical records application with modular architecture. The project follows clean architecture principles with separation of concerns across multiple packages, specifically designed for healthcare data management.

## Development Commands

### Essential Setup Commands
```bash
# Install global dependencies (run once)
dart pub global activate melos
dart pub global activate mason_cli

# Bootstrap the entire workspace
melos bootstrap

# Initialize Mason templates
mason get

# Prepare for development (generates code, runs build runner)
melos run prepare
```

### Core Development Workflow
```bash
# Run static analysis across all packages
melos run analyze

# Fix auto-fixable issues across all packages
melos run fix
melos run fix-dry-run            # Preview fixes before applying

# Format code across all packages
melos run format
melos run format-check           # Check code formatting

# Run tests across all packages
melos run test
melos run test:dart              # Run Dart-only tests
melos run test:flutter           # Run Flutter-only tests

# Generate code (build_runner, l10n)
melos run build-runner
melos run gen-l10n

# Check dependencies and versions
melos run validate-dependencies
melos run outdated
melos run upgrade                # Upgrade dependencies with major versions

# Test Mason bricks separately
melos run brick-test
```

### Individual Package Operations
```bash
# Navigate to any package directory and run:
flutter test                    # Run tests for that package
flutter analyze                 # Analyze that package
dart run build_runner build     # Generate code for that package

# Example: work with database package
cd app_lib/database
flutter test
dart run build_runner build --delete-conflicting-outputs
```

### Running the Application
```bash
# From root directory
flutter run
flutter run -d chrome          # Web
flutter run -d android         # Android
flutter run -d ios            # iOS
```

## Architecture Structure

### Monorepo Organization
- **Main App**: `lib/` - Entry point and main application code
- **API Layer**: `app_api/` - Generated API client code (OpenAPI/Swagger based)
- **State Management**: `app_bloc/` - BLoC pattern implementations for business logic
  - `error_handler` - Global error handling BLoC with severity levels
- **Shared Libraries**: `app_lib/` - Core utilities, themes, localization, database, logging
  - `database` - Drift ORM with SQLite (Hospitals, Departments, Doctors, Treatments, Visits, Resources)
  - `locale` - Internationalization setup with ARB files
  - `provider` - Dependency injection setup
  - `theme` - Theme management with persistence
  - `logging` - Structured logging with file output and CrashReportingWidget
  - `storage` - Resource file storage with SHA256-based naming (see DATA.md)
  - `utils` - Utilities including FieldDependencyHelper for managing field updates
- **UI Components**: `app_widget/` - Reusable widgets and UI elements
  - `adaptive` - Adaptive UI components for different screen sizes
  - `feedback` - Enhanced feedback system (dialogs, toasts, bottom sheets)
  - `web_view` - Web viewing capabilities
  - `resources` - Resource management widgets
- **Code Generation**: `bricks/` - Mason templates for scaffolding
- **Third-party**: `third_party/` - Modified/custom third-party packages
  - `form_bloc` - Custom form BLoC implementation
  - `flutter_form_bloc` - Flutter form BLoC extensions
  - `flutter_adaptive_scaffold` - Adaptive scaffold components
  - `settings_ui` - Settings UI components

### Key Data Flow Architecture

The application follows a **clean data flow pattern** with clear separation of concerns:

1. **Database Layer** (`app_lib/database`): Drift ORM with SQLite
   - Tables: Hospitals, Departments, Doctors, Treatments, Visits, Resources
   - Full CRUD operations with companion objects and relationship queries
   - Testing support with `AppDatabase.forTesting()` factory
   - Supports both mobile and web platforms
   - See DATA.md for complete database schema documentation

2. **BLoC Layer** (`app_bloc/*`): Business logic with state management
   - Each domain entity has its own BLoC (HospitalBloc, TreatmentBloc, VisitBloc, etc.)
   - Form BLoCs for complex form handling with validation
   - **ErrorHandlerBloc**: Global error handling with severity classification
   - State classes for loading, loaded, error, and operation success states

3. **Provider Layer** (`app_lib/provider`): Dependency injection
   - `MainProvider` sets up global dependencies (SharedPreferences, AppDatabase)
   - BLoC instances provided at root level for global state
   - Clean separation between UI and business logic

4. **UI Layer** (`lib/screens/`, `app_widget/*`): Declarative UI with GoRouter
   - Screen components organized by domain
   - Reusable form widgets with BLoC integration
   - **Safe Widget Patterns**: Custom widgets like `SafeDropdownFieldBlocBuilder` to prevent assertion errors
   - Consistent navigation with NoTransitionPage

5. **Error Handling Layer** (`app_bloc/error_handler`, `app_widget/feedback`)
   - **CrashReportingWidget**: Wraps entire app for comprehensive error capture
   - **Error Boundaries**: UI error handling with fallback components
   - **Structured Logging**: AppLogger with file output to app support directory
   - **Feedback System**: Dialogs, toasts, and bottom sheets for user notifications

### Entry Points and Key Files

- **Main Entry**: `lib/main.dart` - App initialization, logging setup, database initialization, BLoC providers
- **App Shell**: `lib/app.dart` - MaterialApp.router with ThemeBloc integration and localization
- **Router**: `lib/router.dart` - GoRouter configuration with declarative routing and NoTransitionPage
- **Database**: `app_lib/database/lib/src/database.dart` - Drift database with full CRUD operations
- **Provider**: `app_lib/provider/lib/src/main.dart` - MainProvider dependency injection setup

## Package Dependencies

### Melos Mono Repository Setup

This project uses **Melos** to manage a Flutter monorepo with multiple packages. Melos handles workspace management, dependency resolution, and provides unified commands for development workflows.

### Adding Internal Package Dependencies

When including internal packages in this project, **do not use path dependencies**. Instead:

1. **Use workspace dependencies**: Add internal packages with `<package_name>: any` in `pubspec.yaml`
2. **Include resolution**: Add `resolution: workspace` to the environment section
3. **Let Melos handle path resolution**: Melos automatically resolves these dependencies to the correct local package paths

**Example pubspec.yaml:**
```yaml
name: my_feature_package
environment:
  sdk: ">=3.8.0 <4.0.0"
  resolution: workspace  # Required for Melos workspace

dependencies:
  flutter:
    sdk: flutter
  bloc: ^9.0.0

  # Internal packages - use 'any' version, not paths
  app_database: any
  app_theme: any
  app_provider: any
  visit_bloc: any
```

**❌ Wrong:**
```yaml
dependencies:
  app_database:
    path: ../../app_lib/database  # DON'T DO THIS
```

**✅ Correct:**
```yaml
dependencies:
  app_database: any  # This is correct
```

## Key Architecture Patterns

### BLoC Pattern Implementation
Each domain entity follows the standard BLoC pattern:
- **Events**: User actions (LoadX, AddX, UpdateX, DeleteX)
- **States**: UI states (XInitial, XLoading, XLoaded, XError, XOperationSuccess)
- **BLoC**: Business logic that converts events to states
- Form BLoCs handle complex form validation and submission

### Database Schema Design
The medical records system models these relationships:
- **Hospitals** contain multiple **Departments** and **Doctors**
- **Treatments** represent medical procedures/therapies
- **Visits** are appointments linked to **Treatments** and can have **Resources**
- Proper foreign key relationships and cascade handling
- See DATA.md for complete database schema documentation

### State Management Strategy
- **Global BLoCs**: Provided at app root for entities accessed across multiple screens
- **Theme Management**: ThemeBloc with persistent storage using SharedPreferences
- **Form State**: Dedicated form BLoCs for complex validation and submission workflows
- **Error State**: ErrorHandlerBloc manages global error state with severity levels

### Safe Widget Patterns
The project implements custom safe widgets to prevent common Flutter assertion errors:
- **SafeDropdownFieldBlocBuilder**: Prevents assertion errors in form dropdowns by validating state before rendering
- Used consistently across forms to provide robust dropdown behavior
- Addresses specific Flutter form validation challenges

### Field Dependency Management
The project uses **FieldDependencyHelper** (`app_lib/utils`) to manage cascading field updates without race conditions:
- Eliminates the need for artificial `Future.delayed()` calls
- Provides methods for sequential field updates
- Ensures field updates are processed before dependent callbacks execute
- Use this helper when updating form fields that have dependencies on other fields

### Resource Storage
The application stores resources (images, PDFs) using a hash-based naming system:
- Files stored in `<app_documents_directory>/resources/<visitId>/<sha256sum>.<suffix>`
- `ResourceStorageService` (`app_lib/storage`) handles all file operations
- SHA256 hashing prevents duplicate files and ensures data integrity
- See DATA.md for complete storage specifications

### Logging and Error Handling
- **Structured Logging**: AppLogger with file output to app support directory
- **Crash Reporting**: CrashReportingWidget wraps the entire app with comprehensive error capture
- **Error Boundaries**: UI components handle errors gracefully with fallback states
- **Error Screens**: Dedicated error handling in router configuration
- **Feedback System**: User-friendly error notifications via dialogs, toasts, and bottom sheets

## Code Generation with Mason

The project uses Mason templates for consistent code generation. See BRICKS.md for complete documentation.

```bash
# Generate new BLoC package
mason make simple_bloc -o app_bloc/feature_name --name=feature_name

# Generate new screen
mason make screen --name ScreenName --folder subfolder

# Generate new widget
mason make widget --name WidgetName --type stateless --folder components

# Generate API client
mason make api_client -o app_api/app_api --package_name=app_api
```

## Localization Workflow

The application supports comprehensive internationalization:

### Setup and Generation
```bash
# Generate localization files
melos run gen-l10n

# Localization configuration is in app_lib/locale/l10n.yaml
# ARB files are located in app_lib/locale/lib/src/l10n/
```

### Usage Pattern
- Use `AppLocalizations` or `context.l10n` for accessing localized strings
- All user-facing text should be externalized to ARB files
- Supports multiple locales with automatic detection

## Icon Generation

Multi-platform launcher icons are configured and generated:

```bash
# Icons are configured in pubspec.yaml (flutter_launcher_icons section)
# Generate icons for all platforms (run from root)
flutter pub run flutter_launcher_icons:main
```

Supports: Android, iOS, Windows, macOS with appropriate sizing and formats.

## Testing Strategy

### Test Types and Commands
- **Unit Tests**: Co-located with packages in `test/` directories
- **Widget Tests**: For UI components, especially form widgets
- **Integration Tests**: Use `melos run test` for comprehensive testing
- **Database Testing**: AppDatabase.forTesting() factory for in-memory tests

### Running Specific Tests
```bash
# Run all tests across packages
melos run test

# Run only Dart tests (excludes Flutter widget tests)
melos run test:dart

# Run only Flutter tests (includes widget tests)
melos run test:flutter

# Run tests for specific package
cd app_lib/database
flutter test

# Run tests with coverage
flutter test --coverage
```

### Database Testing Patterns
- Use `AppDatabase.forTesting()` for isolated test databases
- Test CRUD operations with in-memory SQLite
- Mock dependencies for BLoC testing
- Test form validation with various input scenarios

## Custom Third-Party Packages

The project includes customized third-party packages in `third_party/`:

### Form Management
- **form_bloc**: Custom form BLoC implementation extending standard BLoC pattern
- **flutter_form_bloc**: Flutter-specific extensions for form BLoC with validation
- These provide robust form handling with validation, submission, and state management

### UI Components
- **flutter_adaptive_scaffold**: Adaptive scaffold components for responsive design
- **settings_ui**: Settings UI components for consistent settings screens

These packages are modified versions of open-source projects tailored specifically for the medical records application's requirements.

## Configuration Files

- **Melos**: `pubspec.yaml` (workspace configuration with comprehensive scripts)
- **Mason**: `mason.yaml` (code generation templates)
- **Analysis**: `analysis_options.yaml` (excludes generated files, uses flutter_lints)
- **Localization**: `app_lib/locale/l10n.yaml` (i18n configuration)
- **Dependencies**: All internal packages use workspace resolution with `any` versions
- **Icons**: `flutter_launcher_icons` configuration in pubspec.yaml for multi-platform icons

## Additional Documentation

- **BRICKS.md**: Complete guide to Mason brick templates and code generation
- **DATA.md**: Detailed database schema and data structure documentation
- **README.md**: Project overview and getting started guide
