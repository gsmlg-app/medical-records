import 'dart:io';

import 'package:app_database/app_database.dart';
import 'package:app_storage/app_storage.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visit_resource_bloc/visit_resource_bloc.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class MockResource extends Mock implements Resource {}

class MockFile extends Mock implements File {}

class MockResourceStorageService extends Mock
    implements ResourceStorageService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(MockFile());
    registerFallbackValue(ResourceType.document);
  });

  group('VisitResourceBloc', () {
    late MockAppDatabase mockDatabase;
    late VisitResourceBloc resourceBloc;

    setUpAll(() {
      registerFallbackValue(
        ResourcesCompanion.insert(
          visitId: 1,
          type: 'document',
          filePath: '/path/to/test.pdf',
        ),
      );
    });

    setUp(() {
      mockDatabase = MockAppDatabase();
      final mockStorageService = MockResourceStorageService();
      resourceBloc = VisitResourceBloc(mockDatabase, mockStorageService);
    });

    tearDown(() {
      resourceBloc.close();
    });

    test('initial state is VisitResourceStateInitial', () {
      expect(resourceBloc.state, const VisitResourceStateInitial());
    });

    group('LoadResources', () {
      final mockResource = MockResource();
      when(() => mockResource.id).thenReturn(1);
      when(() => mockResource.visitId).thenReturn(1);
      when(() => mockResource.type).thenReturn('document');
      when(() => mockResource.filePath).thenReturn('/path/to/test.pdf');
      when(() => mockResource.createdAt).thenReturn(DateTime.now());
      when(() => mockResource.updatedAt).thenReturn(DateTime.now());

      blocTest<VisitResourceBloc, VisitResourceState>(
        'emits loaded state when resources load successfully',
        setUp: () {
          when(
            () => mockDatabase.getResourcesByVisitId(1),
          ).thenAnswer((_) async => [mockResource]);
        },
        build: () => resourceBloc,
        act: (bloc) => bloc.add(const LoadResources(1)),
        expect: () => [
          const VisitResourceStateLoading(),
          VisitResourceStateLoaded([mockResource]),
        ],
      );

      blocTest<VisitResourceBloc, VisitResourceState>(
        'emits error state when loading fails',
        setUp: () {
          when(
            () => mockDatabase.getResourcesByVisitId(1),
          ).thenThrow(Exception('Database error'));
        },
        build: () => resourceBloc,
        act: (bloc) => bloc.add(const LoadResources(1)),
        expect: () => [
          const VisitResourceStateLoading(),
          const VisitResourceStateError('Exception: Database error'),
        ],
      );
    });

    group('AddResource', () {
      final mockFile = MockFile();
      final mockResource = MockResource();
      late MockResourceStorageService mockStorageService;

      setUp(() {
        mockStorageService = MockResourceStorageService();
        when(() => mockFile.path).thenReturn('test.pdf');
        when(() => mockFile.length()).thenAnswer((_) async => 1024);
        when(() => mockFile.exists()).thenAnswer((_) async => true);
        when(
          () => mockFile.openRead(0, 1024),
        ).thenAnswer((_) => Stream.value(List.filled(1024, 0)));
        when(
          () => mockDatabase.createResource(any()),
        ).thenAnswer((_) async => 1);
        when(() => mockResource.id).thenReturn(1);
        when(() => mockResource.visitId).thenReturn(1);
        when(() => mockResource.type).thenReturn('document');
        when(() => mockResource.filePath).thenReturn('/path/to/test.pdf');
        when(() => mockResource.createdAt).thenReturn(DateTime.now());
        when(() => mockResource.updatedAt).thenReturn(DateTime.now());

        // Mock the storage service
        when(
          () => mockStorageService.storeResourceFile(
            visitId: 1,
            sourceFile: mockFile,
            type: ResourceType.document,
          ),
        ).thenAnswer((_) async => '/path/to/stored/test.pdf');
      });

      blocTest<VisitResourceBloc, VisitResourceState>(
        'emits loaded state with new resource when file is valid',
        build: () {
          when(
            () => mockDatabase.getResourcesByVisitId(1),
          ).thenAnswer((_) async => []);
          when(
            () => mockDatabase.createResource(any()),
          ).thenAnswer((_) async => 1);
          return VisitResourceBloc(mockDatabase, mockStorageService);
        },
        seed: () => const VisitResourceStateLoaded([]),
        act: (bloc) => bloc.add(AddResource(mockFile, 1)),
        expect: () => [
          const VisitResourceStateLoading(),
          isA<VisitResourceStateLoaded>(),
        ],
      );

      blocTest<VisitResourceBloc, VisitResourceState>(
        'emits error state when file is too large',
        setUp: () {
          when(
            () => mockFile.length(),
          ).thenAnswer((_) async => 11 * 1024 * 1024); // 11MB
        },
        build: () => resourceBloc,
        seed: () => const VisitResourceStateLoaded([]),
        act: (bloc) => bloc.add(AddResource(mockFile, 1)),
        expect: () => [
          const VisitResourceStateLoading(),
          const VisitResourceStateError(
            'Exception: File size exceeds 10MB limit',
          ),
        ],
      );

      blocTest<VisitResourceBloc, VisitResourceState>(
        'emits error state when file type is not allowed',
        setUp: () {
          when(() => mockFile.path).thenReturn('test.exe');
        },
        build: () => resourceBloc,
        seed: () => const VisitResourceStateLoaded([]),
        act: (bloc) => bloc.add(AddResource(mockFile, 1)),
        expect: () => [
          const VisitResourceStateLoading(),
          const VisitResourceStateError('Exception: File type not allowed'),
        ],
      );
    });

    group('ClearResources', () {
      blocTest<VisitResourceBloc, VisitResourceState>(
        'emits loaded state with empty resources',
        build: () => resourceBloc,
        seed: () => const VisitResourceStateLoaded([]),
        act: (bloc) => bloc.add(const ClearResources()),
        expect: () => [
          const VisitResourceStateLoading(),
          const VisitResourceStateLoaded([]),
        ],
      );
    });

    group('getCurrentResources', () {
      test('returns current resources list', () {
        final mockResource = MockResource();
        resourceBloc.resources = [mockResource];

        final result = resourceBloc.getCurrentResources();

        expect(result, contains(mockResource));
        expect(result, isA<List<Resource>>());
      });
    });

    group('clearCurrentResources', () {
      test('clears current resources', () {
        final mockResource = MockResource();
        resourceBloc.resources = [mockResource];

        resourceBloc.clearCurrentResources();

        expect(resourceBloc.resources, isEmpty);
      });
    });
  });
}
