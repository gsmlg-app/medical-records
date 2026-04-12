import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';

/// Helper utilities for testing export/import functionality
class TestHelpers {
  /// Creates a temporary directory for testing
  static Future<Directory> createTempDirectory() async {
    final tempDir = await Directory.systemTemp.createTemp(
      'medical_records_test_',
    );
    return tempDir;
  }

  /// Cleans up temporary directory after tests
  static Future<void> cleanupTempDirectory(Directory dir) async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Creates a test resource file with given content
  static Future<File> createTestResourceFile(
    Directory dir,
    String filename,
    List<int> content,
  ) async {
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(content);
    return file;
  }

  /// Creates a fake image file for testing
  static Future<File> createFakeImageFile(
    Directory dir,
    String filename,
  ) async {
    // Create a minimal valid JPEG header
    final jpegHeader = [
      0xFF, 0xD8, 0xFF, 0xE0, // JPEG SOI and APP0 marker
      0x00, 0x10, // APP0 length
      0x4A, 0x46, 0x49, 0x46, 0x00, // "JFIF\0"
      0x01, 0x01, // Version 1.1
      0x00, // No units
      0x00, 0x01, 0x00, 0x01, // Density 1x1
      0x00, 0x00, // No thumbnail
      0xFF, 0xD9, // JPEG EOI marker
    ];
    return createTestResourceFile(dir, filename, jpegHeader);
  }

  /// Creates a fake PDF file for testing
  static Future<File> createFakePdfFile(Directory dir, String filename) async {
    // Minimal valid PDF structure
    final pdfContent = '''%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [] /Count 0 >>
endobj
xref
0 3
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
trailer
<< /Size 3 /Root 1 0 R >>
startxref
109
%%EOF''';
    return createTestResourceFile(dir, filename, pdfContent.codeUnits);
  }

  /// Validates ZIP file structure
  static Future<bool> validateZipStructure(
    File zipFile, {
    bool requireManifest = true,
    bool requireResourcesDir = false,
  }) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      if (requireManifest) {
        final hasManifest = archive.files.any((f) => f.name == 'manifest.json');
        if (!hasManifest) return false;
      }

      if (requireResourcesDir) {
        final hasResources = archive.files.any(
          (f) => f.name.startsWith('resources/'),
        );
        if (!hasResources) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Extracts manifest.json from ZIP file
  static Future<String?> extractManifestFromZip(File zipFile) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final manifestFile = archive.files.firstWhere(
        (f) => f.name == 'manifest.json',
      );

      if (manifestFile.isFile) {
        final content = manifestFile.content as List<int>;
        return String.fromCharCodes(content);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Creates a corrupted ZIP file for error testing
  static Future<File> createCorruptedZipFile(Directory dir) async {
    final file = File(p.join(dir.path, 'corrupted.zip'));
    // Write invalid ZIP data
    await file.writeAsBytes([0x00, 0x01, 0x02, 0x03]);
    return file;
  }

  /// Creates a ZIP file with missing manifest for error testing
  static Future<File> createZipWithoutManifest(Directory dir) async {
    final archive = Archive();
    final file = ArchiveFile('dummy.txt', 5, [0x68, 0x65, 0x6C, 0x6C, 0x6F]);
    archive.addFile(file);

    final zipData = ZipEncoder().encode(archive);
    final zipFile = File(p.join(dir.path, 'no_manifest.zip'));
    await zipFile.writeAsBytes(zipData);
    return zipFile;
  }

  /// Creates a ZIP file with invalid manifest JSON
  static Future<File> createZipWithInvalidManifest(Directory dir) async {
    final archive = Archive();
    final invalidJson = 'This is not valid JSON {]';
    final file = ArchiveFile(
      'manifest.json',
      invalidJson.length,
      invalidJson.codeUnits,
    );
    archive.addFile(file);

    final zipData = ZipEncoder().encode(archive);
    final zipFile = File(p.join(dir.path, 'invalid_manifest.zip'));
    await zipFile.writeAsBytes(zipData);
    return zipFile;
  }

  /// Creates a ZIP file with valid manifest but missing resource files
  static Future<File> createZipWithMissingResources(
    Directory dir,
    String manifestJson,
  ) async {
    final archive = Archive();
    final file = ArchiveFile(
      'manifest.json',
      manifestJson.length,
      manifestJson.codeUnits,
    );
    archive.addFile(file);

    final zipData = ZipEncoder().encode(archive);
    final zipFile = File(p.join(dir.path, 'missing_resources.zip'));
    await zipFile.writeAsBytes(zipData);
    return zipFile;
  }

  /// Compares two DateTime objects ignoring microseconds
  static bool datesEqual(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;

    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute &&
        a.second == b.second;
  }

  /// Custom matcher for DateTime comparison (ignoring microseconds)
  static Matcher dateTimeEquals(DateTime expected) {
    return predicate<DateTime>(
      (actual) => datesEqual(actual, expected),
      'DateTime equals $expected (ignoring microseconds)',
    );
  }
}

/// Mock file system for testing file operations without actual I/O
class MockFileSystem {
  final Map<String, List<int>> _files = {};

  void writeFile(String path, List<int> bytes) {
    _files[path] = bytes;
  }

  List<int>? readFile(String path) {
    return _files[path];
  }

  bool fileExists(String path) {
    return _files.containsKey(path);
  }

  void deleteFile(String path) {
    _files.remove(path);
  }

  void clear() {
    _files.clear();
  }

  int get fileCount => _files.length;
}
