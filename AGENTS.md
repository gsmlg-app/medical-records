# Build/Lint/Test Commands
- Run single test: `flutter test test/widget_test.dart`
- Run all tests: `flutter test` or `melos exec flutter test`
- Lint: `melos run lint:all` (analyze + format)
- Format: `melos run format`
- Analyze: `melos run analyze`
- Build: `melos run build-all`
- Generate localization: `melos run gen-l10n`
- Prepare project: `melos run prepare`
- Fix code: `melos run fix`
- Check dependencies: `melos run validate-dependencies`

# Code Style Guidelines
- Use flutter_lints from analysis_options.yaml
- Import order: dart, package, local (as seen in main.dart)
- Use single quotes for strings (prefer_single_quotes rule available)
- Prefer const constructors
- Use BLoC pattern for state management (flutter_bloc, equatable)
- Error handling: try/catch with logging (app_logging package)
- Naming: PascalCase for classes, camelCase for variables
- Types: always specify return types and parameter types
- Workspace structure: use melos for monorepo management
- Generated files: exclude *.g.dart, *.freezed.dart from analysis
- Dependencies: use workspace packages with `any` version constraint
- Testing: use mockito for mocking, build_test for test utilities