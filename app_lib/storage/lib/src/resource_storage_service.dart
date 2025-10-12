import 'dart:io';
import 'package:app_database/app_database.dart';
import 'package:app_logging/app_logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Service for handling resource file operations following DATA.md specifications
/// Storage format: <app_document_directory>/resources/<visitId>/<uuid>.<suffix>
class ResourceStorageService {
  static const String _resourcesDirName = 'resources';

  /// Get the base resources directory in app documents
  Future<Directory> get _resourcesBaseDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final resourcesDir = Directory(path.join(appDir.path, _resourcesDirName));

    if (!resourcesDir.existsSync()) {
      resourcesDir.createSync(recursive: true);
      AppLogger().d('Created resources base directory: ${resourcesDir.path}');
    }

    return resourcesDir;
  }

  /// Get the directory for a specific visit's resources
  Future<Directory> _getVisitResourceDir(int visitId) async {
    final baseDir = await _resourcesBaseDir;
    final visitDir = Directory(path.join(baseDir.path, visitId.toString()));

    if (!visitDir.existsSync()) {
      await visitDir.create(recursive: true);
      AppLogger().d('Created visit resource directory: ${visitDir.path}');
    }

    return visitDir;
  }

  /// Store a file for a specific visit
  /// Returns the relative file path to store in database
  Future<String> storeResourceFile({
    required int visitId,
    required File sourceFile,
    required ResourceType type,
  }) async {
    try {
      final visitDir = await _getVisitResourceDir(visitId);
      final fileExtension = path.extension(sourceFile.path);
      final uniqueFileName = '${const Uuid().v4()}$fileExtension';
      final targetPath = path.join(visitDir.path, uniqueFileName);

      // Copy the file to the target location
      await sourceFile.copy(targetPath);

      // Return the relative path from the base resources directory
      final relativePath = path.join(visitId.toString(), uniqueFileName);

      AppLogger().d('Stored resource file: $relativePath');
      return relativePath;
    } catch (e) {
      AppLogger().e('Failed to store resource file: $e');
      throw Exception('Failed to store resource file: $e');
    }
  }

  /// Get the full file path from a relative path
  Future<File> getResourceFile(String relativePath) async {
    final baseDir = await _resourcesBaseDir;
    final fullPath = path.join(baseDir.path, relativePath);
    return File(fullPath);
  }

  /// Delete a resource file
  Future<bool> deleteResourceFile(String relativePath) async {
    try {
      final file = await getResourceFile(relativePath);
      if (file.existsSync()) {
        await file.delete();
        AppLogger().d('Deleted resource file: $relativePath');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger().e('Failed to delete resource file: $e');
      return false;
    }
  }

  /// Clean up all resources for a specific visit
  Future<void> cleanupVisitResources(int visitId) async {
    try {
      final visitDir = await _getVisitResourceDir(visitId);
      if (await visitDir.exists()) {
        await visitDir.delete(recursive: true);
        AppLogger().d('Cleaned up resources for visit $visitId');
      }
    } catch (e) {
      AppLogger().e('Failed to cleanup visit resources: $e');
    }
  }

  /// Check if a resource file exists
  Future<bool> resourceFileExists(String relativePath) async {
    try {
      final file = await getResourceFile(relativePath);
      return file.existsSync();
    } catch (e) {
      AppLogger().e('Failed to check if resource file exists: $e');
      return false;
    }
  }

  /// Get file size in bytes
  Future<int?> getResourceFileSize(String relativePath) async {
    try {
      final file = await getResourceFile(relativePath);
      if (file.existsSync()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      AppLogger().e('Failed to get resource file size: $e');
      return null;
    }
  }

  /// Get all resource files for a visit
  Future<List<String>> getVisitResourcePaths(int visitId) async {
    try {
      final visitDir = await _getVisitResourceDir(visitId);
      if (!await visitDir.exists()) {
        return [];
      }

      final files = await visitDir.list().where((entity) => entity is File).cast<File>().toList();
      final baseDir = await _resourcesBaseDir;
      return files.map((file) {
        final relativePath = path.relative(file.path, from: baseDir.path);
        return relativePath;
      }).toList();
    } catch (e) {
      AppLogger().e('Failed to get visit resource paths: $e');
      return [];
    }
  }
}