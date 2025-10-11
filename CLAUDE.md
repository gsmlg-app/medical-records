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

# Format code across all packages
melos run format

# Run tests across all packages
melos run test

# Generate code (build_runner, l10n)
melos run build-runner
melos run gen-l10n

# Check dependencies and versions
melos run validate-dependencies
melos run outdated
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
- **Shared Libraries**: `app_lib/` - Core utilities, themes, localization, database, logging
- **UI Components**: `app_widget/` - Reusable widgets and UI elements
- **Code Generation**: `bricks/` - Mason templates for scaffolding
- **Third-party**: `third_party/` - Modified/custom third-party packages

### Key Data Flow Architecture

The application follows a **clean data flow pattern** with clear separation of concerns:

1. **Database Layer** (`app_database`): Drift ORM with SQLite
   - Tables: Hospitals, Departments, Doctors, Treatments, Visits, Resources
   - CRUD operations with companion objects
   - Supports both mobile and web platforms

2. **BLoC Layer** (`app_bloc/*`): Business logic with state management
   - Each domain entity has its own BLoC (HospitalBloc, TreatmentBloc, VisitBloc, etc.)
   - Form BLoCs for complex form handling with validation
   - State classes for loading, loaded, error, and operation success states

3. **Provider Layer** (`app_provider`): Dependency injection
   - `MainProvider` sets up global dependencies (SharedPreferences, AppDatabase)
   - BLoC instances provided at root level for global state
   - Clean separation between UI and business logic

4. **UI Layer** (`lib/screens/`, `app_widget/*`): Declarative UI with GoRouter
   - Screen components organized by domain
   - Reusable form widgets with BLoC integration
   - Consistent navigation with NoTransitionPage

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

### State Management Strategy
- **Global BLoCs**: Provided at app root for entities accessed across multiple screens
- **Theme Management**: ThemeBloc with persistent storage using SharedPreferences
- **Form State**: Dedicated form BLoCs for complex validation and submission workflows

### Logging and Error Handling
- **Structured Logging**: AppLogger with file output to app support directory
- **Crash Reporting**: CrashReportingWidget wraps the entire app
- **Error Screens**: Dedicated error handling in router configuration

## Code Generation with Mason

The project uses Mason templates for consistent code generation:

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

## Testing Strategy

- **Unit Tests**: Co-located with packages in `test/` directories
- **Widget Tests**: For UI components, especially form widgets
- **Integration Tests**: Use `melos run test` for comprehensive testing
- **Database Testing**: AppDatabase.forTesting() factory for in-memory tests

## Configuration Files

- **Melos**: `pubspec.yaml` (workspace configuration with comprehensive scripts)
- **Mason**: `mason.yaml` (code generation templates)
- **Analysis**: `analysis_options.yaml` (excludes generated files, uses flutter_lints)
- **Localization**: `app_lib/locale/l10n.yaml` (i18n configuration)
- **Dependencies**: All internal packages use workspace resolution with `any` versions