import 'dart:io';

import 'package:app_database/app_database.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_storage/app_storage.dart';
import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';

import 'event.dart';
import 'state.dart';

/// {@template visit_resource_bloc}
/// BLoC for managing visit resources and file operations.
/// {@endtemplate}
class VisitResourceBloc extends Bloc<VisitResourceEvent, VisitResourceState> {
  /// {@macro visit_resource_bloc}
  final AppDatabase _database;
  final ResourceStorageService _storageService;

  /// Resources associated with the current visit
  List<Resource> resources = [];

  /// {@macro visit_resource_bloc}
  VisitResourceBloc(this._database, [ResourceStorageService? storageService])
    : _storageService = storageService ?? ResourceStorageService(),
      super(const VisitResourceStateInitial()) {
    on<LoadResources>(_onLoadResources);
    on<AddResource>(_onAddResource);
    on<RemoveResource>(_onRemoveResource);
    on<ClearResources>(_onClearResources);
  }

  Future<void> _onLoadResources(
    LoadResources event,
    Emitter<VisitResourceState> emit,
  ) async {
    try {
      emit(const VisitResourceStateLoading());

      resources = await _database.getResourcesByVisitId(event.visitId);

      emit(VisitResourceStateLoaded(resources));
    } catch (e) {
      AppLogger().e('Failed to load resources for visit ${event.visitId}: $e');
      emit(VisitResourceStateError(e.toString()));
    }
  }

  Future<void> _onAddResource(
    AddResource event,
    Emitter<VisitResourceState> emit,
  ) async {
    try {
      emit(const VisitResourceStateLoading());

      // Validate file
      await _validateFile(event.file);

      // Store file and get path
      final storedPath = await _storageService.storeResourceFile(
        visitId: event.visitId,
        sourceFile: event.file,
        type: _getResourceType(event.file.path),
      );

      // Create resource record
      final resource = ResourcesCompanion.insert(
        visitId: event.visitId,
        type: _getFileType(event.file.path),
        filePath: storedPath,
        name: const Value(null),
        rotation: const Value(0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );

      final resourceId = await _database.createResource(resource);

      // Create resource object
      final newResource = Resource(
        id: resourceId,
        visitId: event.visitId,
        type: _getFileType(event.file.path),
        filePath: storedPath,
        name: null,
        notes: null,
        rotation: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      resources.add(newResource);

      // Emit loaded state with updated resources
      emit(VisitResourceStateLoaded(List.from(resources)));
    } catch (e) {
      AppLogger().e('Failed to add resource: $e');
      emit(VisitResourceStateError(e.toString()));
    }
  }

  Future<void> _onRemoveResource(
    RemoveResource event,
    Emitter<VisitResourceState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! VisitResourceStateLoaded) {
        emit(const VisitResourceStateError('Resources not loaded'));
        return;
      }

      final resource = resources.firstWhere(
        (r) => r.id == event.resourceId,
        orElse: () => throw Exception('Resource not found'),
      );

      // Delete file from storage
      await _storageService.deleteResourceFile(resource.filePath);

      // Delete from database
      await _database.deleteResource(event.resourceId);

      // Remove from list
      resources.removeWhere((r) => r.id == event.resourceId);

      emit(currentState.copyWith(resources: List.from(resources)));
    } catch (e) {
      AppLogger().e('Failed to remove resource: $e');
      emit(VisitResourceStateError(e.toString()));
    }
  }

  Future<void> _onClearResources(
    ClearResources event,
    Emitter<VisitResourceState> emit,
  ) async {
    try {
      emit(const VisitResourceStateLoading());

      // Delete all files from storage
      for (final resource in resources) {
        try {
          await _storageService.deleteResourceFile(resource.filePath);
        } catch (e) {
          AppLogger().w('Failed to delete file ${resource.filePath}: $e');
        }
      }

      // Clear from database (if visitId is provided)
      if (event.visitId != null) {
        await _database.deleteResourcesByVisitId(event.visitId!);
      }

      resources.clear();

      emit(const VisitResourceStateLoaded([]));
    } catch (e) {
      AppLogger().e('Failed to clear resources: $e');
      emit(VisitResourceStateError(e.toString()));
    }
  }

  Future<void> _validateFile(File file) async {
    // Check file size (10MB limit)
    const maxSize = 10 * 1024 * 1024; // 10MB
    final fileSize = await file.length();

    if (fileSize > maxSize) {
      throw Exception('File size exceeds 10MB limit');
    }

    // Check file type
    final fileName = file.path.toLowerCase();
    final allowedExtensions = [
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', // Images
      '.pdf', '.doc', '.docx', '.txt', '.rtf', // Documents
      '.mp4', '.avi', '.mov', '.wmv', '.flv', // Videos
      '.mp3', '.wav', '.ogg', '.flac', // Audio
      '.zip', '.rar', '.7z', '.tar', '.gz', // Archives
    ];

    final hasValidExtension = allowedExtensions.any(
      (ext) => fileName.endsWith(ext),
    );
    if (!hasValidExtension) {
      throw Exception('File type not allowed');
    }

    // Check if file exists and is readable
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }

    // Try to read first few bytes to ensure it's not corrupted
    try {
      final bytes = await file.openRead(0, 1024).first;
      if (bytes.isEmpty) {
        throw Exception('File is empty');
      }
    } catch (e) {
      throw Exception('File is corrupted or unreadable');
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return 'image';
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
        return 'document';
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
        return 'audio';
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return 'archive';
      default:
        return 'other';
    }
  }

  ResourceType _getResourceType(String fileName) {
    final fileType = _getFileType(fileName);
    switch (fileType) {
      case 'image':
        return ResourceType.image;
      case 'document':
        return ResourceType.document;
      case 'video':
        return ResourceType.video;
      case 'audio':
        return ResourceType.audio;
      case 'archive':
        return ResourceType.other;
      default:
        return ResourceType.other;
    }
  }

  /// Get resources for the current visit
  List<Resource> getCurrentResources() {
    return List.unmodifiable(resources);
  }

  /// Clear all resources (for new visits)
  void clearCurrentResources() {
    resources.clear();
  }
}
